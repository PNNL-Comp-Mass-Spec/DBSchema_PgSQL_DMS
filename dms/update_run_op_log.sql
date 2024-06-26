--
-- Name: update_run_op_log(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_run_op_log(IN _changes text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update selected items from instrument run tracking-related entities, updating tables t_requested_run and/or t_run_interval
**
**      This procedure is used by web page https://dms2.pnl.gov/run_op_logs/grid
**
**      Example contents of _changes:
**        <run request="1263010" usage="RESOURCE_OWNER" proposal="" user="" />
**        <run request="1254406" usage="USER_ONSITE" proposal="60613" user="49073" />
**        <interval id="268646" note="On hold pending scheduling,Broken[50%],CapDev[25%],StaffNotAvailable[25%],Operator[40677]" />
**        <interval id="1176694" note="Test note,UserRemote[100%], Proposal[60046], PropUser[62793]" />
**
**      Note that Interval ID is the ID of the dataset directly before the interval
**
**  Arguments:
**    _changes      XML defining the updates to be applied
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   grk
**  Date:   02/21/2013 grk - Initial release
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - Pass _invalidUsage to add_update_run_interval; continue updating long intervals if the usage info fails validation for a given entry
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          05/24/2022 mem - Do not call post_log_entry for errors of the form 'Total percentage (0) does not add up to 100 for ID 1017648'
**          10/20/2023 mem - Ported to PostgreSQL
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user()
**          01/08/2024 mem - Remove procedure name from error message
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := true;
    _xml xml;
    _autoPopulateUserListIfBlank boolean := true;
    _requestID int;
    _eusUsageTypeID int;
    _eusUsageType text;
    _eusProposalID text;
    _eusUsersList text;
    _statusID int;
    _msg text;
    _comment text;
    _invalidUsage int := 0;     -- Leave as an integer since add_update_run_interval is called from a web page
    _invalidEntries int := 0;
    _targetType int;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        _xml = public.try_cast(_changes, null::xml);

        If _xml Is Null Then
            _message := 'Unable to convert text in _changes to XML';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Make temp table to hold requested run changes
        -- and populate it from the input XML
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_RequestedRunUsageInfo (
            request int NULL,
            usage text NULL,
            proposal text NULL,
            emsl_user text NULL,
            statusID int NULL
        );

        INSERT INTO Tmp_RequestedRunUsageInfo (request, usage, proposal, emsl_user)
        SELECT XmlQ.request, Trim(XmlQ.usage), Trim(XmlQ.proposal), Trim(XmlQ.emsl_user)
        FROM (
            SELECT xmltable.*
            FROM (SELECT ('<updates>' || _xml::text || '</updates>')::xml AS rooted_xml
                 ) Src,
                 XMLTABLE('//updates/run'
                          PASSING Src.rooted_xml
                          COLUMNS request   int  PATH '@request',
                                  usage     text PATH '@usage',
                                  proposal  text PATH '@proposal',
                                  emsl_user text PATH '@user')
             ) XmlQ;

        -- Get current status of request (needed for change log updating)

        UPDATE Tmp_RequestedRunUsageInfo
        SET statusID = TRSN.State_ID
        FROM t_requested_run RR
             INNER JOIN t_requested_run_state_name TRSN
               ON RR.state_name = TRSN.state_name
        WHERE Tmp_RequestedRunUsageInfo.request = RR.request_id;

        ---------------------------------------------------
        -- Create temporary table to hold interval changes
        -- and populate it from the input XML
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_IntervalUpdates (
            id int,
            note text
        );

        INSERT INTO Tmp_IntervalUpdates (id, note)
        SELECT XmlQ.request, Trim(XmlQ.note)
        FROM (
            SELECT xmltable.*
            FROM (SELECT ('<updates>' || _xml::text || '</updates>')::xml AS rooted_xml
                 ) Src,
                 XMLTABLE('//updates/interval'
                          PASSING Src.rooted_xml
                          COLUMNS request int  PATH '@id',
                                  note    text PATH '@note')
             ) XmlQ;

        -----------------------------------------------------------
        -- Loop through requested run changes, validate, and update
        -----------------------------------------------------------

        FOR _requestID, _eusUsageType, _eusProposalID, _eusUsersList, _statusID IN
            SELECT request, usage, proposal, emsl_user, statusID
            FROM Tmp_RequestedRunUsageInfo
            ORDER BY request
        LOOP
            CALL public.validate_eus_usage (
                            _eusUsageType                => _eusUsageType,      -- Input/Output
                            _eusProposalID               => _eusProposalID,     -- Input/Output
                            _eusUsersList                => _eusUsersList,      -- Input/Output
                            _eusUsageTypeID              => _eusUsageTypeID,    -- Output
                            _autoPopulateUserListIfBlank => _autoPopulateUserListIfBlank,
                            -- _samplePrepRequest        => false,
                            -- _experimentID             => 0,
                            -- _campaignID               => 0,
                            -- _addingItem               => _addingItem,
                            -- _infoOnly                 => false,
                            _message                     => _msg,               -- Output
                            _returnCode                  => _returnCode         -- Output
                        );

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

            -----------------------------------------------------------
            -- Update the requested run
            -----------------------------------------------------------

            UPDATE t_requested_run
            SET eus_proposal_id = _eusProposalID,
                eus_usage_type_id = _eusUsageTypeID
            WHERE request_id = _requestID;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                _targetType := 11;
                CALL public.alter_event_log_entry_user ('public', _targetType, _requestID, _statusID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Assign users to the request

            CALL public.assign_eus_users_to_requested_run (
                                    _requestID    => _requestID,
                                    _eusUsersList => _eusUsersList,
                                    _message      => _msg,              -- Output
                                    _returnCode   => _returnCode);      -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Message from assign_eus_users_to_requested_run: %', _msg;
            End If;

        END LOOP;

        ---------------------------------------------------
        -- Loop though long intervals and update
        ---------------------------------------------------

        FOR _requestID, _comment IN
            SELECT id, note
            FROM Tmp_IntervalUpdates
            ORDER BY id
        LOOP
            CALL public.add_update_run_interval (
                            _requestID,
                            _comment,
                            'update',
                            _message      => _msg,              -- Output
                            _returnCode   => _returnCode,       -- Output
                            _callingUser  => _callingUser,
                            _showDebug    => false,
                            _invalidUsage => _invalidUsage);    -- Output

            If _invalidUsage > 0 Then
                -- Update _message then continue to the next item
                _message := public.append_to_text(_message, _msg);
                _invalidEntries := _invalidEntries + 1;
            ElsIf _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

        END LOOP;

        If _invalidEntries > 0 Then
            If _message Like '%Total percentage%' Then
                _logErrors := false;
            End If;

            -- _msg will be 'Parse error: error details' or 'Parse errors: error details'
            _msg := format('Parse %s: %s', public.check_plural(_invalidEntries, 'error', 'errors'), _message);

            RAISE EXCEPTION '%', _msg;
        End If;

        DROP TABLE Tmp_RequestedRunUsageInfo;
        DROP TABLE Tmp_IntervalUpdates;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_RequestedRunUsageInfo;
    DROP TABLE IF EXISTS Tmp_IntervalUpdates;
END
$$;


ALTER PROCEDURE public.update_run_op_log(IN _changes text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_run_op_log(IN _changes text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_run_op_log(IN _changes text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRunOpLog';

