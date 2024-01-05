--
-- Name: add_update_capture_step_tools(text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.add_update_capture_step_tools(IN _name text, IN _description text, IN _bionetrequired text, IN _onlyonstorageserver text, IN _instrumentcapacitylimited text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing step tool in cap.t_step_tools
**
**  Arguments:
**    _name                         Step tool name
**    _description                  Description
**    _bionetRequired               'Y' or 'N' for whether bionet is required
**    _onlyOnStorageServer          'Y' or 'N' for whether the tool can only be used on the same storage server as the running manager
**    _instrumentCapacityLimited    'Y' or 'N' indicating whether the number of running instances of a given tool should be limited for a given instrument
**    _mode                         Mode: 'add' or 'update'
**    _message                      Status message
**    _returnCode                   Return code
**    _callingUser                  Username of the calling user
**
**  Auth:   grk
**  Date:   09/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/06/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Raise a warning if an invalid operation
**          12/09/2022 mem - Change _mode to lowercase
**          04/27/2023 mem - Use boolean for data type name
**          05/12/2023 mem - Rename variables
**          05/23/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          01/03/2024 mem - Update warning messages
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _stepToolId int;
    _existingCount int;

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
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT step_tool_id
        INTO _stepToolId
        FROM  cap.t_step_tools
        WHERE step_tool = _name::citext;
        --
        GET DIAGNOSTICS _existingCount = ROW_COUNT;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        -- Cannot update a non-existent entry

        If _mode = 'update' And _existingCount = 0 Then
            _message := format('Cannot update: step tool "%s" does not exist', _name);
            RAISE WARNING '%', _message;
            _returnCode := 'U5201';
            RETURN;
        End If;

        -- Cannot add an existing entry

        If _mode = 'add' And _existingCount > 0 Then
            _message := format('Cannot add: step tool "%s" already exists', _name);
            RAISE WARNING '%', _message;
            _returnCode := 'U5202';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

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

        If _mode = 'update' Then

            UPDATE cap.t_step_tools
            SET
                description = _description,
                bionet_required = _bionetRequired,
                only_on_storage_server = _onlyOnStorageServer,
                instrument_capacity_limited = _instrumentCapacityLimited
            WHERE step_tool = _name::citext;

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

