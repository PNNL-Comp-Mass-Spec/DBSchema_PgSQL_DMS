--
CREATE OR REPLACE FUNCTION sw.copy_runtime_metadata_from_history
(
    _jobList text,
    _infoOnly boolean = false,
)
RETURNS TABLE (
    job int,
    update_required boolean,
    invalid boolean,
    comment citext,
    dataset citext,
    step int,
    tool citext,
    statename citext,
    state int2,
    new_state int2,
    start timestamp,
    finish timestamp,
    new_start timestamp,
    new_finish timestamp,
    input_folder citext,
    output_folder citext,
    processor citext,
    new_processor citext,
    tool_version_id int,
    tool_version citext,
    completion_code int,
    completion_message citext,
    evaluation_code int,
    evaluation_message citext
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copies selected pieces of metadata from the history tables
**      to sw.T_Jobs and sw.T_Job_Steps. Specifically:
**          Start, Finish, Processor,
**          Completion_Code, Completion_Message,
**          Evaluation_Code, Evaluation_Message,
**          Tool_Version_ID, Remote_Info_ID,
**          Remote_Timestamp, Remote_Start, Remote_Finish
**
**      This function is intended to be used in situations where
**      a job step was manually re-run for debugging purposes,
**      and the files created by the job step were only used
**      for comparison purposes back to the original results
**
**      It will only copy the runtime metadata if the Results_Transfer (or Results_Cleanup) steps
**      in sw.T_Job_Steps match exactly the Results_Transfer (or Results_Cleanup) steps in sw.T_Job_Steps_History
**
**  Example usage:
**
**      SELECT * FROM sw.copy_runtime_metadata_from_history('1962713', false);
**
**  Auth:   mem
**  Date:   10/19/2017 mem - Initial release
**          10/31/2017 mem - Look for job states with state 4 or 5 and a null Finish time, but a start time later than a Results_Transfer step
**          02/17/2018 mem - Treat Results_Cleanup steps the same as Results_Transfer steps
**          04/27/2018 mem - Use T_Job_Steps instead of V_Job_Steps so we can see the Start and Finish times for the job step (and not Remote_Start or Remote_Finish)
**          01/04/2021 mem - Add support for PRIDE_Converter jobs
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text;
    _myRowCount int := 0;
    _job int;
    _jobStep int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _jobList := Coalesce(_jobList, '');
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create two temporary tables
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_Jobs (
        Job int not null,
        Update_Required boolean not null,
        Invalid boolean not null,
        Comment text null
    );

    CREATE TEMP TABLE Tmp_JobStepsToUpdate (
        Job int not null,
        Step int not null
    );

    ---------------------------------------------------
    -- Populate a temporary table with jobs to process
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Jobs (Job, Update_Required, Invalid)
    SELECT Value as Job, false, false
    FROM public.parse_delimited_integer_list(_jobList, ',');

    If Not Exists (SELECT * FROM Tmp_Jobs) Then
        _message := 'No valid jobs were found: ' || _jobList;

        RETURN QUERY
        SELECT     0 As job,
                false As update_required,
                true As invalid,
                _message::citext As "comment",
                format('Jobs: %s', _jobList)::citext As dataset,
                step int,
                ''::citext As tool,
                ''::citext As statename,
                0::int2 As state,
                0::int2 As new_state,
                null::timestamp As "start",
                null::timestamp As finish,
                null::timestamp As new_start,
                null::timestamp As new_finish,
                ''::citext As input_folder,
                ''::citext As output_folder,
                ''::citext As processor,
                ''::citext As new_processor,
                0 As tool_version_id,
                ''::citext As tool_version,
                0 As completion_code,
                ''::citext As completion_message,
                0 As evaluation_code,
                ''::citext As evaluation_message;

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_JobStepsToUpdate;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Find job steps that need to be updated
    ---------------------------------------------------

    ---------------------------------------------------
    -- First look for jobs with a Finish date after the Start date of the corresponding Results_Transfer step
    --
    INSERT INTO Tmp_JobStepsToUpdate( job, step )
    SELECT JS.job, JS.step
    FROM Tmp_Jobs
         INNER JOIN sw.t_job_steps JS
           ON Tmp_Jobs.job = JS.job
         INNER JOIN ( SELECT job, step, start, input_folder_name
                      FROM sw.t_job_steps
                      WHERE (tool In ('Results_Transfer', 'Results_Cleanup'))
                    ) FilterQ
           ON JS.job = FilterQ.job AND
              JS.output_folder_name = FilterQ.input_folder_name AND
              JS.finish > FilterQ.start AND
              JS.step < FilterQ.step
    WHERE Not JS.tool In ('Results_Transfer', 'Results_Cleanup');

    ---------------------------------------------------
    -- Next Look for job steps that are state 4 or 5 (Running or Complete) with a null Finish date,
    -- but which started after their corresponding Results_Transfer step
    --
    INSERT INTO Tmp_JobStepsToUpdate( job, step )
    SELECT JS.job, JS.step
    FROM Tmp_Jobs
         INNER JOIN sw.t_job_steps JS
           ON Tmp_Jobs.job = JS.job
         INNER JOIN ( SELECT job, step, start, input_folder_name
                      FROM sw.t_job_steps
                      WHERE (tool In ('Results_Transfer', 'Results_Cleanup'))
                    ) FilterQ
           ON JS.job = FilterQ.job AND
              JS.output_folder_name = FilterQ.input_folder_name AND
              JS.finish Is Null AND
              JS.start > FilterQ.start AND
              JS.step < FilterQ.step
    WHERE Not JS.tool In ('Results_Transfer', 'Results_Cleanup');

    ---------------------------------------------------
    -- Look for PRIDE_Converter job steps
    --
    INSERT INTO Tmp_JobStepsToUpdate( job, step )
    SELECT JS.job, JS.step
    FROM Tmp_Jobs
         INNER JOIN sw.t_job_steps JS
           ON Tmp_Jobs.job = JS.job
    WHERE JS.tool = 'PRIDE_Converter';

    ---------------------------------------------------
    -- Update the job list table using Tmp_JobStepsToUpdate
    --
    UPDATE Tmp_Jobs
    SET Update_Required = true
    WHERE Job IN ( SELECT DISTINCT Job
                   FROM Tmp_JobStepsToUpdate );

    ---------------------------------------------------
    -- Look for jobs with Update_Required = false
    ---------------------------------------------------
    --
    UPDATE Tmp_Jobs
    SET Comment = 'Nothing to update; no job steps were started (or completed) after their corresponding Results_Transfer or Results_Cleanup step'
    WHERE Not Update_Required;

    ---------------------------------------------------
    -- Look for jobs where the Results_Transfer steps do not match sw.t_job_steps_history
    ---------------------------------------------------
    --
    UPDATE Tmp_Jobs
    SET Comment = format('Results_Transfer step in sw.t_job_steps has a different start/finish value vs. sw.t_job_steps_history; ' ||
                         'step %s; start %s vs. %s; finish %s vs. %s',
                           InvalidQ.step,
                           public.timestamp_text(InvalidQ.start),  public.timestamp_text(InvalidQ.start_history),
                           public.timestamp_text(InvalidQ.finish), public.timestamp_text(InvalidQ.finish_history)),
        Invalid = true
    FROM ( SELECT JS.job,
                  JS.step AS Step,
                  JS.start, JS.finish,
                  JSH.start AS Start_History,
                  JSH.finish AS Finish_History
           FROM sw.t_job_steps JS
                INNER JOIN sw.t_job_steps_history JSH
                  ON JS.job = JSH.job AND
                     JS.step = JSH.step AND
                     JSH.most_recent_entry = 1
           WHERE JS.job IN (Select DISTINCT job FROM Tmp_JobStepsToUpdate) AND
                 JS.tool In ('Results_Transfer', 'Results_Cleanup') AND
                 (JSH.start <> JS.start OR JSH.finish <> JS.finish)
          ) InvalidQ
    WHERE Tmp_Jobs.job = InvalidQ.job;

    If _infoOnly Then
        UPDATE Tmp_Jobs
        SET Comment = 'Metadata would be updated'
        FROM Tmp_JobStepsToUpdate JSU
        WHERE J.Job = JSU.Job AND Not J.Invalid;
    End If;

    If Not _infoOnly And Exists (
        SELECT *
        FROM Tmp_Jobs J INNER JOIN
             Tmp_JobStepsToUpdate JSU
               ON J.Job = JSU.Job
        WHERE Not J.Invalid) Then

        ---------------------------------------------------
        -- Update metadata for the job steps in Tmp_JobStepsToUpdate,
        -- filtering out any jobs with Invalid = true
        ---------------------------------------------------
        --
        UPDATE sw.t_job_steps
        SET start = JSH.start,
            finish = JSH.finish,
            state = JSH.state,
            processor = JSH.processor,
            completion_code = JSH.completion_code,
            completion_message = JSH.completion_message,
            evaluation_code = JSH.evaluation_code,
            evaluation_message = JSH.evaluation_message,
            tool_version_id = JSH.tool_version_id,
            remote_info_id = JSH.remote_info_id
        FROM Tmp_Jobs J
             INNER JOIN Tmp_JobStepsToUpdate JSU
               ON J.job = JSU.job
             INNER JOIN sw.t_job_steps JS
               ON JS.job = JSU.job AND
                  JSU.step = JS.step
             INNER JOIN sw.t_job_steps_history JSH
               ON JS.job = JSH.job AND
                  JS.step = JSH.step AND
                  JSH.most_recent_entry = 1
        WHERE Not J.Invalid;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _message := 'No job steps were updated; this indicates a bug.  Examine the temp table contents';

            -- ToDo: Update this to use RAISE INFO

            SELECT 'Tmp_Jobs' AS TheTable, *
            FROM Tmp_Jobs;

            SELECT 'Tmp_JobStepsToUpdate' AS TheTable, *
            FROM Tmp_JobStepsToUpdate;

        End If;

        If _myRowCount = 1 Then
            SELECT JSU.Job,
                   JSU.Step
            INTO _job, _jobStep
            FROM Tmp_Jobs J
                 INNER JOIN Tmp_JobStepsToUpdate JSU
                   ON J.Job = JSU.Job
            WHERE NOT J.Invalid;

            _message := format('Updated step %s for job %s in sw.t_job_steps, copying metadata from sw.t_job_steps_history', _jobStep, _job);
        End If;

        If _myRowCount > 1 Then
            _message := format('Updated %s job steps in sw.t_job_steps, copying metadata from sw.t_job_steps_history', _myRowCount);
        End If;

        UPDATE Tmp_Jobs
        SET Comment = 'Metadata updated'
        FROM Tmp_JobStepsToUpdate JSU
        WHERE J.Job = JSU.Job AND Not J.Invalid;

    End If;

    ---------------------------------------------------
    -- Show job steps that were updated, or would be updated, or that cannot be updated
    ---------------------------------------------------
    --
    RETURN QUERY
    SELECT J.job,
           J.Update_Required,
           J.Invalid,
           J.Comment,
           JS.Dataset,
           JS.step,
           JS.Tool,
           JS.StateName,
           JS.state,
           JSH.state as New_State,
           JS.start,
           JS.finish,
           JSH.start AS New_Start,
           JSH.finish AS New_Finish,
           JS.Input_Folder,
           JS.Output_Folder,
           JS.processor,
           JSH.processor AS New_Processor,
           JS.tool_version_id,
           JS.Tool_Version,
           JS.completion_code,
           JS.completion_message,
           JS.evaluation_code,
           JS.evaluation_message
    FROM Tmp_JobStepsToUpdate JSU
         INNER JOIN V_Job_Steps JS
           ON JSU.job = JS.job AND
              JSU.step = JS.step
         INNER JOIN sw.t_job_steps_history JSH
           ON JS.job = JSH.job AND
              JS.step = JSH.step AND
              JSH.most_recent_entry = 1
         RIGHT OUTER JOIN Tmp_Jobs J
           ON J.job = JSU.job

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_JobStepsToUpdate;

END
$$;

COMMENT ON PROCEDURE sw.copy_runtime_metadata_from_history IS 'CopyRuntimeMetadataFromHistory';
