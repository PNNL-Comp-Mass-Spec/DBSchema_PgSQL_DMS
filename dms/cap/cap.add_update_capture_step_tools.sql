--
-- Name: add_update_capture_step_tools(text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.add_update_capture_step_tools(IN _name text, IN _description text, IN _bionetrequired text, IN _onlyonstorageserver text, IN _instrumentcapacitylimited text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing T_Step_Tools
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   09/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/06/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Raise a warning if an invalid operation
**          12/09/2022 mem - Change _mode to lowercase
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized bool;

    _stepToolId int;
    _myRowCount int;

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

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT step_tool_id
        INTO _stepToolId
        FROM  cap.t_step_tools
        WHERE step_tool = _name;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        -- Cannot update a non-existent entry
        --
        If _mode = 'update' And _myRowCount = 0 Then
            _message := 'Could not find "' || _name || '" in database';
            RAISE WARNING '%', _message;
            _returnCode := 'U5201';
            RETURN;
        End If;

        -- Cannot add an existing entry
        --
        If _mode = 'add' And _myRowCount > 0 Then
            _message := '"' || _name || '" already exists in database';
            RAISE WARNING '%', _message;
            _returnCode := 'U5202';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        --
        If _mode = 'add' Then

            INSERT INTO cap.t_step_tools (
                step_tool,
                description,
                bionet_required,
                only_on_storage_server,
                instrument_capacity_limited
            ) VALUES (
                _name,
                _description,
                _bionetRequired,
                _onlyOnStorageServer,
                _instrumentCapacityLimited
            );

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then

            UPDATE cap.t_step_tools
            SET
                description = _description,
                bionet_required = _bionetRequired,
                only_on_storage_server = _onlyOnStorageServer,
                instrument_capacity_limited = _instrumentCapacityLimited
            WHERE step_tool = _name;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;
END
$$;


ALTER PROCEDURE cap.add_update_capture_step_tools(IN _name text, IN _description text, IN _bionetrequired text, IN _onlyonstorageserver text, IN _instrumentcapacitylimited text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

