--
-- Name: add_update_instrument_usage_report(integer, integer, text, text, text, integer, integer, integer, integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_instrument_usage_report(IN _seq integer, IN _emslinstid integer, IN _instrument text, IN _type text, IN _start text, IN _minutes integer, IN _year integer, IN _month integer, IN _id integer, IN _proposal text, IN _usage text, IN _users text, IN _operator text, IN _comment text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Edit an existing instrument usage entry
**      (despite the procedure name, only updates are allowed)
**
**  Arguments:
**    _seq          Row ID; column seq in t_emsl_instrument_usage_report
**    _emslInstID   EMSL Instrument ID (only used when logging an error)
**    _instrument   Unused (not updatable)
**    _type         Unused (not updatable)
**    _start        Unused (not updatable)
**    _minutes      Unused (not updatable)
**    _year         Unused (not updatable)
**    _month        Unused (not updatable)
**    _id           Dataset_ID (only used when logging an error)
**    _proposal     EUS proposal for updating a usage entry
**    _usage        Usage type (ONSITE, REMOTE, MAINTENANCE, BROKEN, etc.); corresponds to t_emsl_instrument_usage_type
**    _users        EUS user IDs (comma-separated list)
**    _operator     Operator ID, corresponding to person_id in t_eus_users (should be an integer representing EUS Person ID; if an empty string, will store NULL for the operator ID)
**    _comment      Comment
**    _mode         The only supported mode is 'update'
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user (unused by this procedure)
**
**  Auth:   grk
**  Date:   03/27/2012
**          09/11/2012 grk - Changed type of _start
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/11/2017 mem - Replace column Usage with Usage_Type
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/05/2018 mem - Assure that _comment does not contain LF or CR
**          04/17/2020 mem - Use Dataset_ID instead of ID
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          01/15/2024 mem - Ported to PostgreSQL
**          03/02/2024 mem - If _users is not null, trim whitespace
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _matchCount int;
    _usageTypeID int;
    _operatorID int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _proposal := Trim(Coalesce(_proposal, ''));
        _usage    := Trim(Coalesce(_usage, ''));
        _comment  := Trim(Coalesce(_comment, ''));
        _mode     := Trim(Lower(Coalesce(_mode, '')));

        If _usage = '' Then
            RAISE EXCEPTION 'Usage %', _usage;
        End If;

        SELECT usage_type_id
        INTO _usageTypeID
        FROM t_emsl_instrument_usage_type
        WHERE usage_type = _usage::citext;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _matchCount = 0 Or Coalesce(_usageTypeID, 0) = 0 Then
            RAISE EXCEPTION 'Invalid usage %', _usage;
        End If;

        -- Assure that _operator is either an integer or null
        _operatorID := public.try_cast(_operator, null::int);

        -- Assure that _comment does not contain LF or CR
        _comment := Trim(Replace(Replace(_comment, chr(10), ' '), chr(13), ' '));

        -- If _users is not null, trim whitespace
        If Not _users Is Null Then
            _users := Trim(_users);
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            If _seq Is Null Then
                RAISE EXCEPTION 'Cannot update: sequence ID cannot be null';
            End If;

            If Not Exists (SELECT dataset_id FROM t_emsl_instrument_usage_report WHERE seq = _seq) Then
                RAISE EXCEPTION 'Cannot update EMSL instrument usage: sequence ID % does not exist in the instrument usage report table', _seq;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            RAISE EXCEPTION '"Add" mode is not supported';
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_emsl_instrument_usage_report
            SET proposal      = _proposal,
                usage_type_id = _usageTypeID,
                users         = _users,
                operator      = _operatorID,
                comment       = _comment
            WHERE seq = _seq;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _seq Is Null Then
            _logMessage := format('%s; Null Seq, EMSL Instrument ID %s, Dataset ID %s', _exceptionMessage, Coalesce(_emslInstID, 0), Coalesce(_id, 0));
        Else
            If Position(_seq::text In _exceptionMessage) > 0 Then
                _logMessage := format('%s; EMSL Instrument ID %s, Dataset ID %s', _exceptionMessage, _seq, Coalesce(_emslInstID, 0), Coalesce(_id, 0));
            Else
                _logMessage := format('%s; Seq %s, EMSL Instrument ID %s, Dataset ID %s', _exceptionMessage, _seq, Coalesce(_emslInstID, 0), Coalesce(_id, 0));
            End If;
        End If;

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_instrument_usage_report(IN _seq integer, IN _emslinstid integer, IN _instrument text, IN _type text, IN _start text, IN _minutes integer, IN _year integer, IN _month integer, IN _id integer, IN _proposal text, IN _usage text, IN _users text, IN _operator text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_instrument_usage_report(IN _seq integer, IN _emslinstid integer, IN _instrument text, IN _type text, IN _start text, IN _minutes integer, IN _year integer, IN _month integer, IN _id integer, IN _proposal text, IN _usage text, IN _users text, IN _operator text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_instrument_usage_report(IN _seq integer, IN _emslinstid integer, IN _instrument text, IN _type text, IN _start text, IN _minutes integer, IN _year integer, IN _month integer, IN _id integer, IN _proposal text, IN _usage text, IN _users text, IN _operator text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateInstrumentUsageReport';

