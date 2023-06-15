--
CREATE OR REPLACE PROCEDURE public.add_update_instrument_usage_report
(
    _seq int,
    _eMSLInstID int,
    _instrument text,
    _type text,
    _start text,
    _minutes int,
    _year int,
    _month int,
    _id int,
    _proposal text,
    _usage text,
    _users text,
    _operator text,
    _comment text,
    _mode text = 'update',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing item in T_EMSL_Instrument_Usage_Report
**
**  Arguments:
**    _eMSLInstID   _eMSLInstID
**    _instrument   Unused (not updatable)
**    _type         Unused (not updatable)
**    _start        Unused (not updatable)
**    _minutes      Unused (not updatable)
**    _year         Unused (not updatable)
**    _month        Unused (not updatable)
**    _id           Unused (not updatable)     -- Dataset_ID
**    _proposal     Proposal for update
**    _usage        Usage name for update (ONSITE, REMOTE, MAINTENANCE, BROKEN, etc.); corresponds to T_EMSL_Instrument_Usage_Type
**    _users        Users for update
**    _operator     Operator for update (should be an integer representing EUS Person ID; if an empty string, will store NULL for the operator ID)
**    _comment      Comment for update
**    _mode         The only supported mode is update
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _matchCount int;
    _usageTypeID int;

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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, '')));
        _usage := Coalesce(_usage, '');

        SELECT usage_type_id
        INTO _usageTypeID
        FROM t_emsl_instrument_usage_type
        WHERE usage_type = _usage;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _matchCount = 0 Or Coalesce(_usageTypeID, 0) = 0 Then
            RAISE EXCEPTION 'Invalid usage %', _usage;
        End If;

        -- Assure that _operator is either an integer or null
        _operator := try_cast(_operator, null::int);

        -- Assure that _comment does not contain LF or CR
        _comment := Replace(Replace(_comment, chr(10), ' '), chr(13), ' ');

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            If Not Exists (SELECT dataset_id FROM t_emsl_instrument_usage_report WHERE seq = _seq) Then
                RAISE EXCEPTION 'No entry could be found in database for update';
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            RAISE EXCEPTION '"Add" mode not supported';
        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            --
            UPDATE t_emsl_instrument_usage_report
            SET
                proposal = _proposal,
                usage_type_id = _usageTypeID,
                users = _users,
                operator = _operator,
                comment = _comment
            WHERE seq = _seq;

        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; Job %s', _exceptionMessage, _job);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

END
$$;

COMMENT ON PROCEDURE public.add_update_instrument_usage_report IS 'AddUpdateInstrumentUsageReport';
