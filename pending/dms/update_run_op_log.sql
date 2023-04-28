--
CREATE OR REPLACE PROCEDURE public.update_run_op_log
(
    _changes text,
    INOUT _message text = '',
    INOUT _returnCode text = '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update selected items from instrument run tracking-related entities
**
**      Example contents of _changes:
**        <run request="206498" usage="USER" proposal="123456" user="1001" />
**        <interval id="268646" note="On hold pending scheduling,Broken[50%],CapDev[25%],StaffNotAvailable[25%],Operator[40677]" />
**
**  Arguments:
**    _changes      Tracks the updates to be applied, in XML format
**
**  Auth:   grk
**  Date:   02/21/2013 grk - Initial release
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - Pass _invalidUsage to AddUpdateRunInterval; continue updating long intervals if the usage info fails validation for a given entry
**          06/12/2018 mem - Send _maxLength to AppendToText
**          05/24/2022 mem - Do not call PostlogEntry for errors of the form 'Total percentage (0) does not add up to 100 for ID 1017648'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _logErrors boolean := true;
    _xml XML;;
    _autoPopulateUserListIfBlank boolean := true,
    _curID int;
    _eusUsageTypeID int,
    _eusUsageType text,
    _eusProposalID text,
    _eusUsersList text,
    _statusID int
    _msg text;
    _comment text;
    _invalidUsage int := 0;     -- Leave as an integer
    _invalidEntries int := 0;

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

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        _xml = public.try_cast(_changes, null::xml);

        If _xml Is Null Then
            _message := 'Unable to convert text in _changes to XML';
            REPORT WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Make temp table to hold requested run changes
        -- and populate it from the input XML
        -----------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_RequestedRunUsageInfo (
            request int NULL,
            usage text NULL,
            proposal text NULL,
            emsl_user text NULL,
            statusID int null
        )

        INSERT INTO Tmp_RequestedRunUsageInfo
            (request, usage,  proposal,emsl_user)
        SELECT
            xmlNode.value('@request', 'text') request,
            xmlNode.value('@usage', 'text') usage,
            xmlNode.value('@proposal', 'text') proposal,
            xmlNode.value('@user', 'text') emsl_user
        FROM _xml.nodes('//run') AS R(xmlNode);

        -- Get current status of request (needed for change log updating)
        --
        UPDATE Tmp_RequestedRunUsageInfo
        Set statusID = TRSN.State_ID
        FROM t_requested_run RR
             INNER JOIN t_requested_run_state_name TRSN
               ON RR.state_name = TRSN.state_name
        WHERE Tmp_RequestedRunUsageInfo.request = RR.request_id;

        ---------------------------------------------------
        -- Create temp table to hold interval changes
        -- and populate it from the input XML
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_IntervalUpdates (
            id int,
            note text
        )

        INSERT INTO Tmp_IntervalUpdates
            (id, note)
        SELECT
            xmlNode.value('@id', 'text') request,
            xmlNode.value('@note', 'text') note
        FROM _xml.nodes('//interval') AS R(xmlNode);

        -----------------------------------------------------------
        -- Loop through requested run changes
        -- and validate and update
        -----------------------------------------------------------

        FOR
            SELECT request, usage, proposal, emsl_user, statusID
            INTO _curID, _eusUsageType, _eusProposalID, _eusUsersList, _statusID
            FROM Tmp_IntervalUpdates
            ORDER BY request
        LOOP
            Call validate_eus_usage (
                            _eusUsageType   => _eusUsageType,       -- Input/Output
                            _eusProposalID  => _eusProposalID,      -- Input/Output
                            _eusUsersList   => _eusUsersList,       -- Input/Output
                            _eusUsageTypeID => _eusUsageTypeID,     -- Output
                            _message => _msg,                       -- Output
                            _returnCode => _returnCode,             -- Output
                            _autoPopulateUserListIfBlank => _autoPopulateUserListIfBlank);

            If _returnCode <> '' Then
                RAISE EXCEPTION 'ValidateEUSUsage: %', _msg;
            End If;

            -----------------------------------------------------------
            -- Update the requested run
            -----------------------------------------------------------

            UPDATE t_requested_run
            SET eus_proposal_id = _eusProposalID,
                eus_usage_type_id = _eusUsageTypeID
            WHERE request_id = _curID;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If char_length(_callingUser) > 0 Then
                Call alter_event_log_entry_user (11, _curID, _statusID, _callingUser);
            End If;

            -- Assign users to the request
            --
            Call assign_eus_users_to_requested_run
                                    _curID,
                                    _eusProposalID,
                                    _eusUsersList,
                                    _msg output
            If _returnCode <> '' Then
                RAISE EXCEPTION 'assign_eus_users_to_requested_run: %', _msg;
            End If;

        END LOOP;

        ---------------------------------------------------
        -- Loop though long intervals and update
        ---------------------------------------------------
        --

        FOR
            SELECT id, note
            INTO _curID, _comment
            FROM Tmp_IntervalUpdates
            ORDER BY id
        LOOP
            Call add_update_run_interval (
                                        _curID,
                                        _comment,
                                        'update',
                                        _message => _msg,                   -- Output
                                        _callingUser => _callingUser,
                                        _showDebug => false,
                                        _invalidUsage => _invalidUsage);     -- Output

            If _invalidUsage > 0 Then
                -- Update _message then continue to the next item
                _message := public.append_to_text(_message, _msg, 0, '; ', 512);
                _invalidEntries := _invalidEntries + 1;
            ElsIf _returnCode <> ''
                RAISE EXCEPTION 'add_update_run_interval: %', _msg;
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

COMMENT ON PROCEDURE public.update_run_op_log IS 'UpdateRunOpLog';
