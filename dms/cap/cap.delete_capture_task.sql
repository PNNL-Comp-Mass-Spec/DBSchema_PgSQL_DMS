--
-- Name: delete_capture_task(integer, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.delete_capture_task(IN _job integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the given capture task job from t_tasks and t_task_steps, t_task_step_dependencies, and t_task_parameters
**
**  Arguments:
**    _job          Capture task job number
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   mem
**  Date:   09/12/2009 mem - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/11/2012 mem - Renamed from DeleteJob to DeleteCaptureTask
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/11/2022 mem - Ported to PostgreSQL
**          04/27/2023 mem - Use boolean for data type name
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          12/08/2023 mem - Select a single column when using If Not Exists()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

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

        If Not Exists (SELECT job FROM cap.t_tasks WHERE Job = _job) THEN
            _message := format('Capture task job %s not found in cap.t_tasks', _job);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Delete the capture task job dependencies
        ---------------------------------------------------

        DELETE FROM cap.t_task_step_dependencies
        WHERE Job = _job;

        ---------------------------------------------------
        -- Delete the capture task job parameters
        ---------------------------------------------------

        DELETE FROM cap.t_task_parameters
        WHERE Job = _job;

        ---------------------------------------------------
        -- Delete the capture task job steps
        ---------------------------------------------------

        DELETE FROM cap.t_task_steps
        WHERE Job = _job;

        ---------------------------------------------------
        -- Delete the capture task job
        ---------------------------------------------------

        DELETE FROM cap.t_tasks
        WHERE Job = _job;

        _message := format('Deleted capture task job %s', _job);
        RAISE INFO '%', _message;

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


ALTER PROCEDURE cap.delete_capture_task(IN _job integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_capture_task(IN _job integer, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.delete_capture_task(IN _job integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteCaptureTask';

