--
-- Name: copy_history_to_task(integer, boolean, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.copy_history_to_task(IN _job integer, IN _assignnewjobnumber boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For a given capture task job, copy the job details, steps, and parameters
**      from the most recent successful run in the history tables back into the main tables
**
**  Arguments:
**    _job                  Capture task job number
**    _assignNewJobNumber   Set to true to assign a new capture task job number when copying
**    _message              Status message
**    _returnCode           Return code
**    _debugMode            When true, show debug messages
**
**  Auth:   grk
**  Date:   02/06/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from t_task_steps
**          03/12/2012 mem - Added column Tool_Version_ID
**          03/21/2012 mem - Now disabling identity_insert prior to inserting a row into t_tasks
**                         - Fixed bug finding most recent successful capture task job in t_tasks_history
**          08/27/2013 mem - Now calling Update_Parameters_For_Job
**          10/21/2013 mem - Added _assignNewJobNumber
**          03/10/2015 mem - Added t_task_step_dependencies_history
**          03/10/2015 mem - Now updating t_task_steps.Dependencies if it doesn't match the dependent steps listed in t_task_step_dependencies
**          10/10/2022 mem - Ported to PostgreSQL
**          03/07/2023 mem - Use new column name
**          04/02/2023 mem - Rename procedure and functions
**          05/12/2023 mem - Rename variables
**          05/19/2023 mem - Remove redundant parentheses
**          05/22/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(job) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _currentLocation text := 'Start';
    _dateStamp timestamp;
    _newJob int;
    _jobDateDescription text;
    _similarJob int;
    _jobList text;
    _insertCount int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';
    _debugMode := Coalesce(_debugMode, false);

    If _debugMode Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

    If Coalesce(_job, 0) = 0 Then
        _message := 'Capture task job number is 0 or null; nothing to do';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    _assignNewJobNumber := Coalesce(_assignNewJobNumber, false);

    If _debugMode Then
        RAISE INFO 'Looking for capture task job % in the history tables', _job;
    End If;

    ---------------------------------------------------
    -- Bail if capture task job already exists in main tables
    ---------------------------------------------------

    If Exists (SELECT job FROM cap.t_tasks WHERE job = _job) Then
        _message := format('Job %s already exists in cap.t_tasks; aborting', _job);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Get capture task job status from most recent completed historic capture task job
    ---------------------------------------------------

    SELECT MAX(saved)
    INTO _dateStamp
    FROM cap.t_tasks_history
    WHERE job = _job AND state = 3;

    If _dateStamp Is Null Then
        RAISE INFO 'No successful capture task jobs found in cap.t_tasks_history for capture task job %; will look for a failed capture task job', _job;

        -- Find most recent historic capture task job, regardless of job state

        SELECT MAX(saved)
        INTO _dateStamp
        FROM cap.t_tasks_history
        WHERE job = _job;

        If Not FOUND Then
            _message := format('Capture task job not found in t_tasks_history: %s', _job);
            RAISE WARNING '%', _message;

            RETURN;
        End If;

        RAISE INFO 'Match found, saved on %', public.timestamp_text(_dateStamp);
    End If;

    BEGIN

        _newJob := _job;
        _jobDateDescription := format('capture task job %s and date %s', _job, _dateStamp);
        _similarJob := 0;
        _jobList := _newJob::text;

        If Not _assignNewJobNumber Then

            _currentLocation := format('Insert into cap.t_tasks from cap.t_tasks_history for %s', _jobDateDescription);

            If _debugMode Then
                RAISE INFO '%', _currentLocation;
            End If;

            INSERT INTO cap.t_tasks (
                job, priority, script, state,
                dataset, dataset_id, results_folder_name,
                imported, start, finish
            )
            OVERRIDING SYSTEM VALUE
            SELECT job, priority, script, state,
                   dataset, dataset_id, results_folder_name,
                   imported, start, finish
            FROM cap.t_tasks_history
            WHERE job = _job AND
                  saved = _dateStamp;

            If Not FOUND Then
                _message := format('No rows were added to cap.t_tasks from cap.t_tasks_history for %s', _jobDateDescription);
                RAISE WARNING '%', _message;

                RETURN;
            End If;

            RAISE INFO 'Added capture task job % to cap.t_tasks', _job;

        Else

            _currentLocation := format('Insert into cap.t_tasks from cap.t_tasks_history for %s; assign a new capture task job number', _jobDateDescription);

            If _debugMode Then
                RAISE INFO '%', _currentLocation;
            End If;

            INSERT INTO cap.t_tasks (
                priority, script, state,
                dataset, dataset_id, results_folder_name,
                imported, start, finish
            )
            SELECT H.priority, H.script, H.state,
                   H.dataset, H.dataset_id, H.results_folder_name,
                   CURRENT_TIMESTAMP, H.start, H.finish
            FROM cap.t_tasks_history H
            WHERE H.job = _job AND
                  H.saved = _dateStamp
            RETURNING job
            INTO _newJob;

            If Not FOUND Then
                _message := format('No rows were added to cap.t_tasks from cap.t_tasks_history for %s', _jobDateDescription);
                RAISE WARNING '%', _message;

                RETURN;
            End If;

            If _newJob is null Then
                _message := format('Job value for inserted row is null for %s', _jobDateDescription);
                RAISE WARNING '%', _message;

                RETURN;
            End If;

            RAISE INFO 'Cloned capture task job % to create job % in cap.t_tasks', _job, _newJob;
        End If;

        ---------------------------------------------------
        -- Copy steps
        ---------------------------------------------------

        _currentLocation := format('Insert into cap.t_task_steps for %s', _jobDateDescription);

        INSERT INTO cap.t_task_steps (
            job,
            step,
            tool,
            state,
            input_folder_name,
            output_folder_name,
            processor,
            start,
            finish,
            tool_version_id,
            completion_code,
            completion_message,
            evaluation_code,
            evaluation_message
        )
        SELECT
            _newJob AS job,
            step,
            tool,
            state,
            input_folder_name,
            output_folder_name,
            processor,
            start,
            finish,
            tool_version_id,
            completion_code,
            completion_message,
            evaluation_code,
            evaluation_message
        FROM cap.t_task_steps_history
        WHERE job = _job AND
              saved = _dateStamp;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Inserted % steps into cap.t_task_steps for %', _insertCount, _jobDateDescription;
        End If;

        -- Change any waiting or enabled steps to state 7 (holding)
        -- This is a safety feature to avoid capture task job steps from starting inadvertently

        UPDATE cap.t_task_steps
        SET state = 7
        WHERE job = _newJob AND
              state IN (1, 2);

        ---------------------------------------------------
        -- Copy parameters
        ---------------------------------------------------

        _currentLocation := format('Insert into cap.t_task_parameters for %s', _jobDateDescription);

        INSERT INTO cap.t_task_parameters (
            job,
            parameters
        )
        SELECT _newJob AS job,
               parameters
        FROM cap.t_task_parameters_history
        WHERE job = _job AND
              saved = _dateStamp;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Inserted % row into cap.t_task_parameters for %', _insertCount, _jobDateDescription;
        End If;

        ---------------------------------------------------
        -- Copy capture task job step dependencies
        ---------------------------------------------------

        _currentLocation := format('Insert into cap.t_task_step_dependencies for %s', _jobDateDescription);

        -- First delete any extra steps for this capture task job that are in t_task_step_dependencies

        DELETE FROM cap.t_task_step_dependencies target
        WHERE EXISTS
            (SELECT 1
             FROM cap.t_task_step_dependencies TSD
                  INNER JOIN (SELECT D.job,
                                     D.step
                              FROM cap.t_task_step_dependencies D
                                   LEFT OUTER JOIN cap.t_task_step_dependencies_history H
                                     ON D.job = H.job AND
                                        D.step = H.step AND
                                        D.Target_Step = H.Target_Step
                              WHERE D.job = _newJob AND
                                    H.job IS NULL
                             ) DeleteQ
                    ON TSD.job = DeleteQ.job AND
                       TSD.step = DeleteQ.step
             WHERE target.job = TSD.job AND
                   target.step = TSD.step
            );

        -- Check whether this capture task job has entries in t_task_step_dependencies_history

        If Not Exists (SELECT job FROM cap.t_task_step_dependencies_history WHERE job = _job) Then
            -- Capture task job did not have cached dependencies
            -- Look for a capture task job that used the same script

            SELECT MIN(H.job)
            INTO _similarJob
            FROM cap.t_task_step_dependencies_history H
                 INNER JOIN (SELECT job
                             FROM cap.t_tasks_history
                             WHERE job > _job AND
                                   script = (SELECT script
                                             FROM cap.t_tasks_history
                                             WHERE job = _job AND
                                                   most_recent_entry = 1)
                            ) SimilarJobQ
                   ON H.job = SimilarJobQ.job;

            If FOUND Then
                If _debugMode Then
                    RAISE INFO 'Insert Into cap.t_task_step_dependencies using model capture task job %', _similarJob;
                End If;

                INSERT INTO cap.t_task_step_dependencies (
                    job, step, target_step, condition_test, test_value,
                    evaluated, triggered, enable_only
                )
                SELECT _newJob AS job, step, target_step, condition_test, test_value, 0 as evaluated, 0 as triggered, enable_only
                FROM cap.t_task_step_dependencies_history H
                WHERE job = _similarJob;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _debugMode Then
                    RAISE INFO 'Added % rows to cap.t_task_step_dependencies for % using model capture task job %', _insertCount, _jobDateDescription, _similarJob;
                End If;

            Else
                -- No similar capture task jobs
                -- Create default dependencies

                If _debugMode Then
                    RAISE INFO 'Create default dependencies for capture task job %', _newJob;
                End If;

                INSERT INTO cap.t_task_step_dependencies (
                    job,
                    step,
                    target_step,
                    evaluated,
                    triggered,
                    enable_only
                )
                SELECT job,
                       step,
                       step - 1 as target_step,
                       0 as evaluated,
                       0 as triggered,
                       0 as enable_only
                FROM cap.t_task_steps
                WHERE job = _newJob AND
                      step > 1;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _debugMode Then
                    RAISE INFO 'Added % rows to cap.t_task_step_dependencies for %', _insertCount, _jobDateDescription;
                End If;
            End If;

        Else

            If _debugMode Then
                RAISE INFO 'Insert into cap.t_task_step_dependencies using cap.t_task_step_dependencies_history for %', _jobDateDescription;
            End If;

            -- Now add/update the capture task job step dependencies

            INSERT INTO cap.t_task_step_dependencies (job, step, target_step, condition_test, test_value, evaluated, triggered, enable_only)
            SELECT _newJob AS job,
                   step,
                   target_step,
                   condition_test,
                   test_value,
                   evaluated,
                   triggered,
                   enable_only
            FROM cap.t_task_step_dependencies_history
            WHERE job = _job
            ON CONFLICT (job, step, target_step)
            DO UPDATE SET
                condition_test = EXCLUDED.condition_test,
                test_value = EXCLUDED.test_value,
                evaluated = EXCLUDED.evaluated,
                triggered = EXCLUDED.triggered,
                enable_only = EXCLUDED.enable_only;

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
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

    ---------------------------------------------------
    -- Manually create the capture task job parameters if they were not present in t_task_parameters
    ---------------------------------------------------

    If Not Exists (SELECT job FROM cap.t_task_parameters WHERE job = _newJob) Then
        If _debugMode Then
            RAISE INFO 'Capture task job % was not found in cap.t_task_parameters_history; re-generating the parameters using cap.update_parameters_for_task', _newJob;
        End If;

        CALL cap.update_parameters_for_task (
                    _newJob::text,
                    _message => _message,           -- Output
                    _returnCode => _returnCode);    -- Output
    End If;

    ---------------------------------------------------
    -- Make sure the Storage_Server is up-to-date in t_tasks
    ---------------------------------------------------

    If _debugMode Then
        RAISE INFO 'Verifying storage server info by calling cap.update_parameters_for_task for capture task job %', _newJob;
    End If;

    CALL cap.update_parameters_for_task (
                _jobList,
                _message    => _message,        -- Output
                _returnCode => _returnCode);    -- Output

    ---------------------------------------------------
    -- Make sure the Dependencies column is up-to-date in t_task_steps
    ---------------------------------------------------

    UPDATE cap.t_task_steps target
    SET dependencies = CountQ.dependencies
    FROM (SELECT step,
                 COUNT(job) AS dependencies
          FROM cap.t_task_step_dependencies
          WHERE job = _newJob
          GROUP BY step
         ) CountQ
    WHERE target.job = _newJob AND
          CountQ.step = target.step AND
          CountQ.dependencies > target.dependencies;

    If _job = _newJob Then
        _message := format('Copied job %s from the history tables to the active task tables', _job);
    Else
        _message := format('Cloned capture task job %s to create job %s in the active task tables', _job, _newJob);
    End If;

    If _debugMode Then
        RAISE INFO '%', _message;
    End If;

END
$$;


ALTER PROCEDURE cap.copy_history_to_task(IN _job integer, IN _assignnewjobnumber boolean, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_history_to_task(IN _job integer, IN _assignnewjobnumber boolean, INOUT _message text, INOUT _returncode text, IN _debugmode boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.copy_history_to_task(IN _job integer, IN _assignnewjobnumber boolean, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) IS 'CopyHistoryToTask or CopyHistoryToJob';

