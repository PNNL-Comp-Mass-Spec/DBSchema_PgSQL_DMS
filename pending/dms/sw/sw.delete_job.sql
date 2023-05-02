--
CREATE OR REPLACE PROCEDURE sw.delete_job
(
    _job text,
    _callingUser text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes the given job from T_Jobs and T_Job_Steps
**      This procedure was previously called by DeleteAnalysisJob in DMS5
**      However, now DeleteAnalysisJob calls DeleteJobIfNewOrFailed in this database
**
**  Auth:   mem
**  Date:   12/31/2008 mem - initial release
**          05/26/2009 mem - Now deleting from T_Job_Step_Dependencies and T_Job_Parameters
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _jobID int;
BEGIN
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

    _jobID := public.try_cast(_job, null::int);

    If _jobID Is Null Then
        _message := format('Specified job is not an integer: %s', _job);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Delete job dependencies
    ---------------------------------------------------
    --
    DELETE FROM sw.t_job_step_dependencies
    WHERE (job = _jobID);

    ---------------------------------------------------
    -- Delete job parameters
    ---------------------------------------------------
    --
    DELETE FROM sw.t_job_parameters
    WHERE job = _jobID;

    ---------------------------------------------------
    -- Delete job steps
    ---------------------------------------------------
    --
    DELETE FROM sw.t_job_steps
    WHERE job = _jobID;

    ---------------------------------------------------
    -- Delete jobs
    ---------------------------------------------------
    --
    DELETE FROM sw.t_jobs
    WHERE job = _jobID;

END
$$;

COMMENT ON PROCEDURE sw.delete_job IS 'DeleteJob';
