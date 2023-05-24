--
CREATE OR REPLACE PROCEDURE public.do_material_container_operation
(
    _name text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Do an operation on a container, using the container name
**
**  Arguments:
**    _name   Container name
**    _mode   'move_container', 'retire_container', 'retire_container_and_contents', 'unretire_container'
**
**  Auth:   grk
**  Date:   07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          10/01/2009 mem - Expanded error message
**          08/19/2010 grk - try-catch for error handling
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Prevent updating containers of type 'na'
**          07/07/2022 mem - Include container name when logging error messages from UpdateMaterialContainers
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text := '';
    _logMessage text;
    _logErrors boolean := false;
    _tmpID int := 0;
    _iMode text;
    _containerList text;
    _newValue text := '';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _comment text := '';
BEGIN
    _message := '';
    _returnCode:= '';

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
        -- Validate the inputs
        ---------------------------------------------------

        _name := Trim(Coalesce(_name, ''));
        _mode := Trim(Lower(Coalesce(_mode, '')));

        If char_length(_name) = 0 Then
            _msg := 'Container name cannot be empty';
            RAISE EXCEPTION '%', _msg;
        End If;

        If Exists (Select * From V_Material_Container_Item_Stats Where Container = _name And Type = 'na') Then
            _msg := format('Container "%s" cannot be updated by the website; contact a DMS admin (see do_material_container_operation)', _name);
            _logErrors := true;
            RAISE EXCEPTION '%', _msg;
        End If;

        --
        SELECT container_id
        INTO _tmpID
        FROM t_material_containers
        WHERE container = _name;

        If _tmpID = 0 Then
            _msg := format('Could not find the container named "%s" (mode is %s)', _name, _mode);
            RAISE EXCEPTION '%', _msg;
        Else

            _iMode := _mode;
            _containerList := _tmpID;
            _logErrors := true;

            CALL update_material_containers (
                    _iMode,
                    _containerList,
                    _newValue,
                    _comment,
                    _message => _msg,           -- Output
                    _returnCode => _returnCode, -- Output
                    _callingUser);

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            If Position(_name In _message) > 0 Then
                _logMessage := _exceptionMessage;
            Else
                _logMessage := _exceptionMessage || ' (container ' || _name || ')';
            End If;

            _logMessage := format('%s; Dataset %s', _exceptionMessage, _datasetNameOrID);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

END
$$;

COMMENT ON PROCEDURE public.do_material_container_operation IS 'DoMaterialContainerOperation';
