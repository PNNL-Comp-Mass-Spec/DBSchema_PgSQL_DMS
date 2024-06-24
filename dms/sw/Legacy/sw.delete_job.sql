--
-- Name: delete_job(text, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.delete_job(IN _job text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Deletes the given job from T_Jobs and T_Job_Steps
**      This procedure was previously called by public.delete_analysis_job()
**      However, now public.Delete_Analysis_Job calls sw.delete_job_if_new_or_failed()
**
**  Arguments:
**    _job          Job to delete (as text)
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Calling user
*
**  Auth:   mem
**  Date:   12/31/2008 mem - Initial release
**          05/26/2009 mem - Now deleting from T_Job_Step_Dependencies and T_Job_Parameters
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/01/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobID int;
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

    _jobID := public.try_cast(_job, null::int);

    If _jobID Is Null Then
        _message := format('Specified job is not an integer: %s', _job);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Delete job dependencies
    ---------------------------------------------------

    DELETE FROM sw.t_job_step_dependencies
    WHERE (job = _jobID);

    ---------------------------------------------------
    -- Delete job parameters
    ---------------------------------------------------

    DELETE FROM sw.t_job_parameters
    WHERE job = _jobID;

    ---------------------------------------------------
    -- Delete job steps
    ---------------------------------------------------

    DELETE FROM sw.t_job_steps
    WHERE job = _jobID;

    ---------------------------------------------------
    -- Delete jobs
    ---------------------------------------------------

    DELETE FROM sw.t_jobs
    WHERE job = _jobID;

END
$$;


ALTER PROCEDURE sw.delete_job(IN _job text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_job(IN _job text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.delete_job(IN _job text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteJob';

