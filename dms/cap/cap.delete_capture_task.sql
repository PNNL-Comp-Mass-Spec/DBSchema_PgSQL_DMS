--
-- Name: delete_capture_task(integer, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.delete_capture_task(IN _jobnumber integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Deletes the given capture task job from t_tasks and t_task_steps, t_task_step_dependencies, and t_task_parameters
**
**  Auth:   mem
**          09/12/2009 mem - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/11/2012 mem - Renamed from DeleteJob to DeleteCaptureTask
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/11/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized bool;
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

        If Not Exists (SELECT * FROM cap.t_tasks WHERE Job = _jobNumber) THEN
            _message := format('Capture task job %s not found in cap.t_tasks', _jobNumber);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Delete the capture task job dependencies
        ---------------------------------------------------
        --
        DELETE FROM cap.t_task_step_dependencies
        WHERE Job = _jobNumber;

        ---------------------------------------------------
        -- Delete the capture task job parameters
        ---------------------------------------------------
        --
        DELETE FROM cap.t_task_parameters
        WHERE Job = _jobNumber;

        ---------------------------------------------------
        -- Delete the capture task job steps
        ---------------------------------------------------
        --
        DELETE FROM cap.t_task_steps
        WHERE Job = _jobNumber;

        ---------------------------------------------------
        -- Delete the capture task job
        ---------------------------------------------------
        --
        DELETE FROM cap.t_tasks
        WHERE Job = _jobNumber;

        _message := format('Deleted capture task job %s', _jobNumber);
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


ALTER PROCEDURE cap.delete_capture_task(IN _jobnumber integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_capture_task(IN _jobnumber integer, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.delete_capture_task(IN _jobnumber integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteCaptureTask';
