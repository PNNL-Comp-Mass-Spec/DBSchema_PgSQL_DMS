--
-- Name: copy_job_to_history(integer, integer, boolean, timestamp without time zone, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.copy_job_to_history(IN _job integer, IN _jobstate integer, IN _overridesavetime boolean DEFAULT false, IN _savetimeoverride timestamp without time zone DEFAULT NULL::timestamp without time zone, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For a given job, copies the job details, steps, and parameters to the history tables
**
**  Arguments:
**    _job                  Job number
**    _jobState             Current job state
**    _message              Status message
**    _returnCode           Return code
**    _overrideSaveTime     Set to true to use _saveTimeOverride for the SaveTime instead of CURRENT_TIMESTAMP
**    _saveTimeOverride     Timestamp to use when _overrideSaveTime is true
**
**  Auth:   grk
**  Date:   12/17/2008 grk - Initial alpha
**          02/06/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          04/05/2011 mem - Now copying column Special_Processing
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          07/05/2011 mem - Now copying column Tool_Version_ID
**          11/14/2011 mem - Now copying column Transfer_Folder_Path
**          01/09/2012 mem - Added column Owner
**          01/19/2012 mem - Added columns DataPkgID and Memory_Usage_MB
**          03/26/2013 mem - Added column Comment
**          01/20/2014 mem - Added T_Job_Step_Dependencies_History
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          05/13/2017 mem - Add Remote_Info_Id
**          01/19/2018 mem - Add Runtime_Minutes
**          07/25/2019 mem - Add Remote_Start and Remote_Finish
**          08/17/2021 mem - Fix typo in argument _saveTimeOverride
**          08/01/2023 mem - Ported to PostgreSQL
**          08/02/2023 mem - Move the _message and _returnCode arguments to the end of the argument list
**
*****************************************************/
DECLARE
    _saveTime timestamp;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

     If Coalesce(_job, 0) = 0 Then
        _message := 'Job cannot be 0';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Bail if not a state we save for
    ---------------------------------------------------

    If Not Coalesce(_jobState, 0) In (4, 5) Then
        _message := 'Job state must be 4 or 5 to be copied to t_jobs_history (this is not an error)';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Define a common timestamp for all history entries
    ---------------------------------------------------

    If Coalesce(_overrideSaveTime, false) Then
        _saveTime := Coalesce(_saveTimeOverride, CURRENT_TIMESTAMP);
    Else
        _saveTime := CURRENT_TIMESTAMP;
    End If;

    ---------------------------------------------------
    -- Copy jobs
    ---------------------------------------------------

    INSERT INTO sw.t_jobs_history (
        job,
        priority,
        script,
        state,
        dataset,
        dataset_id,
        results_folder_name,
        organism_db_name,
        special_processing,
        imported,
        start,
        finish,
        runtime_minutes,
        transfer_folder_path,
        owner_username,
        data_pkg_id,
        comment,
        saved
    )
    SELECT
        job,
        priority,
        script,
        state,
        dataset,
        dataset_id,
        results_folder_name,
        organism_db_name,
        special_processing,
        imported,
        start,
        finish,
        runtime_minutes,
        transfer_folder_path,
        owner_username,
        data_pkg_id,
        comment,
        _saveTime
    FROM sw.t_jobs
    WHERE job = _job;

    ---------------------------------------------------
    -- Copy Steps
    ---------------------------------------------------

    INSERT INTO sw.t_job_steps_history (
        job,
        step,
        tool,
        memory_usage_mb,
        shared_result_version,
        signature,
        state,
        input_folder_name,
        output_folder_name,
        processor,
        start,
        finish,
        completion_code,
        completion_message,
        evaluation_code,
        evaluation_message,
        saved,
        tool_version_id,
        remote_info_id,
        remote_start,
        remote_finish
    )
    SELECT
        job,
        step,
        tool,
        memory_usage_mb,
        shared_result_version,
        signature,
        state,
        input_folder_name,
        output_folder_name,
        processor,
        start,
        finish,
        completion_code,
        completion_message,
        evaluation_code,
        evaluation_message,
        _saveTime,
        tool_version_id,
        remote_info_id,
        remote_start,
        remote_finish
    FROM sw.t_job_steps
    WHERE job = _job;

    ---------------------------------------------------
    -- Copy parameters
    ---------------------------------------------------

    INSERT INTO sw.t_job_parameters_history (
        job,
        parameters,
        saved
    )
    SELECT job,
           parameters,
           _saveTime
    FROM sw.t_job_parameters
    WHERE job = _job;

    ---------------------------------------------------
    -- Copy job step dependencies
    ---------------------------------------------------

    -- First delete any extra steps for this job that are in sw.t_job_step_dependencies_history

    DELETE FROM sw.t_job_step_dependencies_history target
    WHERE EXISTS
        (  SELECT 1
           FROM sw.t_job_step_dependencies_history TSDH
                INNER JOIN ( SELECT H.Job,
                                    H.Step
                             FROM sw.t_job_step_dependencies_history H
                                  LEFT OUTER JOIN sw.t_job_step_dependencies D
                                    ON H.Job = D.Job AND
                                       H.Step = D.Step AND
                                       H.Target_Step = D.Target_Step
                             WHERE H.Job = _job AND
                                   D.Job IS NULL
                            ) DeleteQ
                  ON TSDH.Job = DeleteQ.Job AND
                     TSDH.Step = DeleteQ.Step
            WHERE target.job = TSDH.job AND
                  target.step = TSDH.step
        );

    -- Now add/update the job step dependencies

    INSERT INTO sw.t_job_step_dependencies_history (job, Step, Target_Step, condition_test, test_value, evaluated, triggered, enable_only, saved)
    SELECT job,
           step,
           target_step,
           condition_test,
           test_value,
           evaluated,
           triggered,
           enable_only,
           _saveTime
    FROM sw.t_job_step_dependencies
    WHERE job = _job
    ON CONFLICT (Job, Step, Target_Step)
    DO UPDATE SET
        condition_test = EXCLUDED.Condition_Test,
        test_value = EXCLUDED.Test_Value,
        evaluated = EXCLUDED.Evaluated,
        triggered = EXCLUDED.Triggered,
        enable_only = EXCLUDED.Enable_Only,
        saved = _saveTime;

    _message := format('Copied job %s to the history tables', _job);
END
$$;


ALTER PROCEDURE sw.copy_job_to_history(IN _job integer, IN _jobstate integer, IN _overridesavetime boolean, IN _savetimeoverride timestamp without time zone, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_job_to_history(IN _job integer, IN _jobstate integer, IN _overridesavetime boolean, IN _savetimeoverride timestamp without time zone, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.copy_job_to_history(IN _job integer, IN _jobstate integer, IN _overridesavetime boolean, IN _savetimeoverride timestamp without time zone, INOUT _message text, INOUT _returncode text) IS 'CopyJobToHistory';

