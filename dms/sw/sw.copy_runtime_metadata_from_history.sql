--
-- Name: copy_runtime_metadata_from_history(integer, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION sw.copy_runtime_metadata_from_history(_job integer, _infoonly boolean DEFAULT false) RETURNS TABLE(job integer, update_required boolean, invalid boolean, mismatch_results_transfer boolean, comment public.citext, dataset public.citext, step integer, tool public.citext, state_name public.citext, state smallint, new_state smallint, start timestamp without time zone, finish timestamp without time zone, new_start timestamp without time zone, new_finish timestamp without time zone, input_folder public.citext, output_folder public.citext, processor public.citext, new_processor public.citext, tool_version_id integer, tool_version public.citext, completion_code integer, completion_message public.citext, evaluation_code integer, evaluation_message public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Copy selected pieces of metadata from the history tables to sw.t_jobs and sw.t_job_steps
*
**      Specifically:
**        Start, Finish, Processor,
**        Completion_Code, Completion_Message,
**        Evaluation_Code, Evaluation_Message,
**        Tool_Version_ID, Remote_Info_ID,
**        Remote_Timestamp, Remote_Start, Remote_Finish
**
**      This function is intended to be used in situations where
**      a job step was manually re-run for debugging purposes,
**      and the files created by the job step were only used
**      for comparison purposes back to the original results
**
**      It will only copy the runtime metadata if the Results_Transfer (or Results_Cleanup) steps
**      in sw.t_job_steps match exactly the Results_Transfer (or Results_Cleanup) steps in sw.t_job_steps_history
**
**      Additionally, data is only copied if the job step with a newer start time
**      has a state of 4 or 5 (Running or Complete) and a null Finish date
**
**  Arguments:
**    _job          Analysis job number
**    _infoOnly     When true, show job steps that would be updated, or that cannot be updated
**
**  Example usage:
**      SELECT * FROM sw.copy_runtime_metadata_from_history(2360508, true);
**      SELECT * FROM sw.copy_runtime_metadata_from_history(2360508, false);
**
**  Auth:   mem
**  Date:   09/18/2024 mem - Initial release
**
*****************************************************/
DECLARE
    _jobList text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job      := Coalesce(_job, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    _jobList  := _job::text;

    ---------------------------------------------------
    -- Query the version of this function that accepts a comma-separated list of job numbers
    ---------------------------------------------------

    RETURN QUERY
    SELECT CM.job,
           CM.update_required,
           CM.invalid,
           CM.mismatch_results_transfer,
           CM.comment,
           CM.dataset,
           CM.step,
           CM.tool,
           CM.state_name,
           CM.state,
           CM.new_state,
           CM.start,
           CM.finish,
           CM.new_start,
           CM.new_finish,
           CM.input_folder,
           CM.output_folder,
           CM.processor,
           CM.new_processor,
           CM.tool_version_id,
           CM.tool_version,
           CM.completion_code,
           CM.completion_message,
           CM.evaluation_code,
           CM.evaluation_message
    FROM sw.copy_runtime_metadata_from_history(_jobList, _infoOnly) CM;

END
$$;


ALTER FUNCTION sw.copy_runtime_metadata_from_history(_job integer, _infoonly boolean) OWNER TO d3l243;

--
-- Name: copy_runtime_metadata_from_history(text, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION sw.copy_runtime_metadata_from_history(_joblist text, _infoonly boolean DEFAULT false) RETURNS TABLE(job integer, update_required boolean, invalid boolean, mismatch_results_transfer boolean, comment public.citext, dataset public.citext, step integer, tool public.citext, state_name public.citext, state smallint, new_state smallint, start timestamp without time zone, finish timestamp without time zone, new_start timestamp without time zone, new_finish timestamp without time zone, input_folder public.citext, output_folder public.citext, processor public.citext, new_processor public.citext, tool_version_id integer, tool_version public.citext, completion_code integer, completion_message public.citext, evaluation_code integer, evaluation_message public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Copy selected pieces of metadata from the history tables to sw.t_jobs and sw.t_job_steps
*
**      Specifically:
**        Start, Finish, Processor,
**        Completion_Code, Completion_Message,
**        Evaluation_Code, Evaluation_Message,
**        Tool_Version_ID, Remote_Info_ID,
**        Remote_Timestamp, Remote_Start, Remote_Finish
**
**      This function is intended to be used in situations where
**      a job step was manually re-run for debugging purposes,
**      and the files created by the job step were only used
**      for comparison purposes back to the original results
**
**      It will only copy the runtime metadata if the Results_Transfer (or Results_Cleanup) steps
**      in sw.t_job_steps match exactly the Results_Transfer (or Results_Cleanup) steps in sw.t_job_steps_history
**
**      Additionally, data is only copied if the job step with a newer start time
**      has a state of 4 or 5 (Running or Complete) and a null Finish date
**
**  Arguments:
**    _jobList      Comma-separated list of job numbers
**    _infoOnly     When true, show job steps that would be updated, or that cannot be updated
**
**  Example usage:
**      SELECT * FROM sw.copy_runtime_metadata_from_history('1962713', false);
**
**  Auth:   mem
**  Date:   10/19/2017 mem - Initial release
**          10/31/2017 mem - Look for job states with state 4 or 5 and a null Finish time, but a start time later than a Results_Transfer step
**          02/17/2018 mem - Treat Results_Cleanup steps the same as Results_Transfer steps
**          04/27/2018 mem - Use T_Job_Steps instead of V_Job_Steps so we can see the Start and Finish times for the job step (and not Remote_Start or Remote_Finish)
**          01/04/2021 mem - Add support for PRIDE_Converter jobs
**          08/01/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _message citext;
    _updateCount int;
    _job int;
    _jobStep int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _jobList  := Trim(Coalesce(_jobList, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create two temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Jobs (
        Job int NOT NULL,
        Update_Required boolean NOT NULL,
        Invalid boolean NOT NULL,                   -- Will be set to True if the job does not exist in sw.t_jobs
        Mismatch_Results_Transfer boolean NOT NULL, -- Will be set to true if the job has a results_Transfer step that has a different start/finish value in sw.t_job_steps vs. sw.t_job_steps_history
        Comment citext NULL
    );

    CREATE TEMP TABLE Tmp_JobStepsToUpdate (
        Job int NOT NULL,
        Step int NOT NULL
    );

    ---------------------------------------------------
    -- Populate a temporary table with jobs to process
    ---------------------------------------------------

    INSERT INTO Tmp_Jobs (
        Job,
        Update_Required,
        Invalid,
        Mismatch_Results_Transfer
    )
    SELECT Value AS Job, false, false, false
    FROM public.parse_delimited_integer_list(_jobList);

    If Not Exists (SELECT * FROM Tmp_Jobs) Then
        _message := format('No valid jobs were found: %s', _jobList);

        RETURN QUERY
        SELECT  0 AS job,
                false AS update_required,
                true AS invalid,
                false AS Mismatch_Results_Transfer,
                _message AS "comment",
                format('Jobs: %s', _jobList)::citext AS dataset,
                step int,
                ''::citext AS tool,
                ''::citext AS state_name,
                0::int2 AS state,
                0::int2 AS new_state,
                null::timestamp AS "start",
                null::timestamp AS finish,
                null::timestamp AS new_start,
                null::timestamp AS new_finish,
                ''::citext AS input_folder,
                ''::citext AS output_folder,
                ''::citext AS processor,
                ''::citext AS new_processor,
                0 AS tool_version_id,
                ''::citext AS tool_version,
                0 AS completion_code,
                ''::citext AS completion_message,
                0 AS evaluation_code,
                ''::citext AS evaluation_message;

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_JobStepsToUpdate;
        RETURN;
    End If;

    UPDATE Tmp_Jobs
    SET Invalid = true
    WHERE NOT EXISTS (SELECT J.job
                      FROM sw.t_jobs J
                      WHERE J.job = Tmp_Jobs.Job);

    If Exists (SELECT * FROM Tmp_Jobs J WHERE J.Invalid) Then
        _message := format('Invalid jobs were found: %s', _jobList);

        RETURN QUERY
        SELECT J.job,
               false AS update_required,
               J.Invalid,
               J.Mismatch_Results_Transfer,
               _message AS "comment",
               ''::citext AS dataset,
               step int,
               ''::citext AS tool,
               ''::citext AS state_name,
               0::int2 AS state,
               0::int2 AS new_state,
               null::timestamp AS "start",
               null::timestamp AS finish,
               null::timestamp AS new_start,
               null::timestamp AS new_finish,
               ''::citext AS input_folder,
               ''::citext AS output_folder,
               ''::citext AS processor,
               ''::citext AS new_processor,
               0 AS tool_version_id,
               ''::citext AS tool_version,
               0 AS completion_code,
               ''::citext AS completion_message,
               0 AS evaluation_code,
               ''::citext AS evaluation_message
        FROM Tmp_Jobs J;

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_JobStepsToUpdate;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Find job steps that need to be updated
    ---------------------------------------------------

    -- First look for jobs with a Finish date after the Start date of the corresponding Results_Transfer step

    INSERT INTO Tmp_JobStepsToUpdate (job, step)
    SELECT JS.job, JS.step
    FROM Tmp_Jobs
         INNER JOIN sw.t_job_steps JS
           ON Tmp_Jobs.job = JS.job
         INNER JOIN (SELECT JSR.job, JSR.step, JSR.start, JSR.input_folder_name
                     FROM sw.t_job_steps JSR
                     WHERE JSR.tool IN ('Results_Transfer', 'Results_Cleanup')
                    ) FilterQ
           ON JS.job = FilterQ.job AND
              JS.output_folder_name = FilterQ.input_folder_name AND
              JS.finish > FilterQ.start AND
              JS.step < FilterQ.step
    WHERE NOT JS.tool IN ('Results_Transfer', 'Results_Cleanup');

    -- Next Look for job steps that are state 4 or 5 (Running or Complete) with a null Finish date,
    -- but which started after their corresponding Results_Transfer step

    INSERT INTO Tmp_JobStepsToUpdate (job, step)
    SELECT JS.job, JS.step
    FROM Tmp_Jobs
         INNER JOIN sw.t_job_steps JS
           ON Tmp_Jobs.job = JS.job
         INNER JOIN (SELECT JSR.job, JSR.step, JSR.start, JSR.input_folder_name
                     FROM sw.t_job_steps JSR
                     WHERE JSR.tool IN ('Results_Transfer', 'Results_Cleanup')
                    ) FilterQ
           ON JS.job = FilterQ.job AND
              JS.output_folder_name = FilterQ.input_folder_name AND
              JS.finish IS NULL AND
              JS.start > FilterQ.start AND
              JS.step < FilterQ.step
    WHERE NOT JS.tool IN ('Results_Transfer', 'Results_Cleanup');

    -- Look for PRIDE_Converter job steps

    INSERT INTO Tmp_JobStepsToUpdate (job, step)
    SELECT JS.job, JS.step
    FROM Tmp_Jobs
         INNER JOIN sw.t_job_steps JS
           ON Tmp_Jobs.job = JS.job
    WHERE JS.tool = 'PRIDE_Converter';

    -- Update the job list table using Tmp_JobStepsToUpdate

    UPDATE Tmp_Jobs target
    SET Update_Required = true
    WHERE target.Job IN (SELECT DISTINCT JSU.Job
                         FROM Tmp_JobStepsToUpdate JSU);

    ---------------------------------------------------
    -- Look for jobs with Update_Required = false
    ---------------------------------------------------

    UPDATE Tmp_Jobs target
    SET Comment = 'Nothing to update; no job steps were started (or completed) after their corresponding Results_Transfer or Results_Cleanup step'
    WHERE NOT target.Update_Required;

    ---------------------------------------------------
    -- Look for jobs where the Results_Transfer steps do not match sw.t_job_steps_history
    ---------------------------------------------------

    UPDATE Tmp_Jobs target
    SET Comment = format('Results_Transfer step in sw.t_job_steps has a different start/finish value vs. sw.t_job_steps_history; '
                         'step %s; start %s vs. %s; finish %s vs. %s',
                           InvalidQ.step,
                           public.timestamp_text(InvalidQ.start),  public.timestamp_text(InvalidQ.start_history),
                           public.timestamp_text(InvalidQ.finish), public.timestamp_text(InvalidQ.finish_history)),
        Mismatch_Results_Transfer = true
    FROM (SELECT JS.job,
                 JS.step AS Step,
                 JS.start, JS.finish,
                 JSH.start AS Start_History,
                 JSH.finish AS Finish_History
          FROM sw.t_job_steps JS
               INNER JOIN sw.t_job_steps_history JSH
                 ON JS.job = JSH.job AND
                    JS.step = JSH.step AND
                    JSH.most_recent_entry = 1
          WHERE JS.job IN (SELECT DISTINCT JSU.job FROM Tmp_JobStepsToUpdate JSU) AND
                JS.tool In ('Results_Transfer', 'Results_Cleanup') AND
                (JSH.start <> JS.start OR JSH.finish <> JS.finish)
         ) InvalidQ
    WHERE target.job = InvalidQ.job;

    If _infoOnly Then
        UPDATE Tmp_Jobs target
        SET Comment = 'Metadata would be updated'
        FROM Tmp_JobStepsToUpdate JSU
        WHERE target.Job = JSU.Job AND NOT target.Mismatch_Results_Transfer;
    End If;

    If Not _infoOnly And Exists (
        SELECT J.job
        FROM Tmp_Jobs J INNER JOIN
             Tmp_JobStepsToUpdate JSU
               ON J.Job = JSU.Job
        WHERE NOT J.Mismatch_Results_Transfer) Then

        ---------------------------------------------------
        -- Update metadata for the job steps in Tmp_JobStepsToUpdate,
        -- filtering out any jobs with Mismatch_Results_Transfer = true
        ---------------------------------------------------

        UPDATE sw.t_job_steps AS target
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
             INNER JOIN sw.t_job_steps_history JSH
               ON JSU.job = JSH.job AND
                  JSU.step = JSH.step AND
                  JSH.most_recent_entry = 1
        WHERE target.job = JSU.job AND
              target.step = JSU.step AND
              Not J.Mismatch_Results_Transfer;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount = 0 Then
            _message := 'No job steps were updated; this indicates a bug. Examine the temp table contents';

            RAISE INFO '';

            _formatSpecifier := '%-8s %-10s %-15s %-8s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Table',
                                'Job',
                                'Update_Required',
                                'Mismatch',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------',
                                         '----------',
                                         '---------------',
                                         '--------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT 'Tmp_Jobs' AS TheTable,
                        Job,
                        Update_Required,
                        Mismatch_Results_Transfer,
                        Comment
                FROM Tmp_Jobs
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.TheTable,
                                    _previewData.Job,
                                    _previewData.Update_Required,
                                    _previewData.Mismatch_Results_Transfer,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            RAISE INFO '';

            _formatSpecifier := '%-20s %-10s %-4s';

            _infoHead := format(_formatSpecifier,
                                'Table',
                                'Job',
                                'Step'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------',
                                         '----------',
                                         '----'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT 'Tmp_JobStepsToUpdate' AS TheTable,
                       Job,
                       Step
                FROM Tmp_JobStepsToUpdate
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.TheTable,
                                    _previewData.Job,
                                    _previewData.Step
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        If _updateCount = 1 Then
            SELECT JSU.Job,
                   JSU.Step
            INTO _job, _jobStep
            FROM Tmp_Jobs J
                 INNER JOIN Tmp_JobStepsToUpdate JSU
                   ON J.Job = JSU.Job
            WHERE NOT J.Mismatch_Results_Transfer;

            _message := format('Updated step %s for job %s in sw.t_job_steps, copying metadata from sw.t_job_steps_history', _jobStep, _job);
        End If;

        If _updateCount > 1 Then
            _message := format('Updated %s job steps in sw.t_job_steps, copying metadata from sw.t_job_steps_history', _updateCount);
        End If;

        UPDATE Tmp_Jobs target
        SET Comment = 'Metadata updated'
        FROM Tmp_JobStepsToUpdate JSU
        WHERE target.Job = JSU.Job AND NOT target.Mismatch_Results_Transfer;

    End If;

    ---------------------------------------------------
    -- Show job steps that were updated, or would be updated, or that cannot be updated
    ---------------------------------------------------

    RETURN QUERY
    SELECT J.job,
           J.Update_Required,
           J.Invalid,
           J.Mismatch_Results_Transfer,
           J.Comment,
           JS.Dataset,
           JS.step,
           JS.Tool,
           JS.state_name,
           JS.state,
           JSH.state AS New_State,
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
           ON J.job = JSU.job;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_JobStepsToUpdate;
END
$$;


ALTER FUNCTION sw.copy_runtime_metadata_from_history(_joblist text, _infoonly boolean) OWNER TO d3l243;

