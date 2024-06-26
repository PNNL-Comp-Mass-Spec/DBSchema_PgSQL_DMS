--
-- Name: do_material_container_operation(text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_material_container_operation(IN _name text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Do an operation on a container, using the container name
**
**  Arguments:
**    _name         Container name
**    _mode         Mode: 'move_container', 'retire_container', 'retire_container_and_contents', 'unretire_container'
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   grk
**  Date:   07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          10/01/2009 mem - Expanded error message
**          08/19/2010 grk - Use try-catch for error handling
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Prevent updating containers of type 'na'
**          07/07/2022 mem - Include container name when logging error messages from Update_Material_Containers
**          02/12/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text := '';
    _logErrors boolean := false;
    _tmpID int;
    _containerList text;
    _newValue text := '';
    _comment text := '';

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

        _name := Trim(Coalesce(_name, ''));
        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _name = '' Then
            _msg := 'Container name must be specified';
            RAISE EXCEPTION '%', _msg;
        End If;

        If Exists (SELECT Container FROM V_Material_Container_Item_Stats WHERE Container = _name::citext AND Type = 'na') Then
            _msg := format('Container "%s" cannot be updated by the website; contact a DMS admin (see Do_Material_Container_Operation)', _name);
            _logErrors := true;
            RAISE EXCEPTION '%', _msg;
        End If;

        SELECT container_id
        INTO _tmpID
        FROM t_material_containers
        WHERE container = _name::citext;

        If _tmpID = 0 Then
            _msg := format('Could not find the container named "%s" (mode is %s)', _name, _mode);
            RAISE EXCEPTION '%', _msg;
        Else

            _containerList := _tmpID::text;
            _logErrors := true;

            CALL public.update_material_containers (
                            _mode          => _mode,
                            _containerList => _containerList,
                            _newValue      => _newValue,
                            _comment       => _comment,
                            _message       => _msg,            -- Output
                            _returnCode    => _returnCode,     -- Output
                            _callingUser   => _callingUser);

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
                _logMessage := format('%s (container %s)', _exceptionMessage, _name);
            End If;

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


ALTER PROCEDURE public.do_material_container_operation(IN _name text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_material_container_operation(IN _name text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_material_container_operation(IN _name text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DoMaterialContainerOperation';

