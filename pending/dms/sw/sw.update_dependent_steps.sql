--
CREATE OR REPLACE PROCEDURE sw.update_dependent_steps
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    INOUT _numStepsSkipped int = 0,
    _infoOnly boolean = false,
    _maxJobsToProcess int = 0,
    _loopingUpdateInterval int = 5
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examine all dependencies for steps in 'Waiting' state
**      and update the state of steps for which all dependencies
**      have been satisfied
**
**      The updated state can be affected by conditions on
**      conditional dependencies and by whether or not the
**      step tool produces shared results
**
**  Arguments:
**    _loopingUpdateInterval   Seconds between detailed logging while looping through the dependencies
**
**  Auth:   grk
**  Date:   05/06/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Optimized performance by switching to a temp table with an indexed column
**                           that specifies the order to process the job steps (http://prismtrac.pnl.gov/trac/ticket/713)
**          01/30/2009 grk - Modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**          03/18/2009 mem - Now checking T_Job_Steps_History for completed shared result steps if no match is found in T_Job_Steps
**          06/01/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter _loopingUpdateInterval
**          10/30/2009 grk - Modified skip logic to not pass through folder for DTARefinery tool (temporary ugly hack)
**          02/15/2010 mem - added some additional debug statements to be shown when _infoOnly is true
**          07/01/2010 mem - Updated DTARefinery skip logic to name the tool DTA_Refinery
**          05/25/2011 mem - Now using the Priority column from T_Jobs
**          12/20/2011 mem - Now updating T_Job_Steps.Dependencies if the dependency count listed is lower than that defined in T_Job_Step_Dependencies
**          09/17/2014 mem - Updated output_folder_name logic to recognize tool Mz_Refinery
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          12/01/2016 mem - Use Disable_Output_Folder_Name_Override_on_Skip when finding shared result step tools for which we should not override Output_Folder_Name when the step is skipped
**          05/13/2017 mem - Add check for state 9=Running_Remote
**          03/30/2018 mem - Rename variables, move Declare statements, reformat queries
**          03/02/2022 mem - For data package based jobs, skip checks for existing shared results
**          03/10/2022 mem - Clear the completion code and completion message when skipping a job step
**                         - Check for a job step with shared results being repeatedly skipped, then reset, then skipped again
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int;
    _jobCount int;
    _msg text;
    _statusMessage text;
    _stepSkipCount int := 0;
    _startTime timestamp := CURRENT_TIMESTAMP;
    _candidateStepCount int;
    _rowCountToProcess int;
    _rowsProcessed int := 0;
    _lastLogTime timestamp := CURRENT_TIMESTAMP;
    _stepInfo record;
    _stepSkipCount int;
    _newState int;
    _newEvaluationMessage text;
    _numCompleted int;
    _numPending int;
    _dataset text;
    _datasetID int;
    _numStepsUpdated int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

    _numStepsSkipped := 0;
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    _message := '';
    _returnCode:= '';
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);
    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    ---------------------------------------------------
    -- Temp table to hold scratch list of step dependencies
    ---------------------------------------------------
    CREATE TEMP TABLE Tmp_Steplist (
        Job int,
        Step int,
        Tool text,
        Priority int,                                -- Holds Job priority
        Total int,
        Evaluated int,
        Triggered int,
        Shared int,
        Signature int,
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Output_Folder_Name text NULL,
        Completion_Code int NULL,
        Completion_Message text NULL,
        Evaluation_Code int NULL,
        Evaluation_Message text NULL,
        ProcessingOrder int NULL                    -- We will populate this column after the Tmp_Steplist table gets populated
    );

    CREATE INDEX IX_StepList_ProcessingOrder ON Tmp_Steplist (ProcessingOrder, Job);

    ---------------------------------------------------
    -- Bump up the value for dependencies in sw.t_job_steps if it is too low
    -- This will happen if new rows are manually added to sw.t_job_step_dependencies
    ---------------------------------------------------
    --
    UPDATE sw.t_job_steps
    SET dependencies = CompareQ.Actual_Dependencies
    FROM ( SELECT job,
                  step,
                  COUNT(*) AS Actual_Dependencies
           FROM sw.t_job_step_dependencies
           WHERE job IN ( SELECT job FROM sw.t_job_steps WHERE state = 1 )
           GROUP BY job, step
         ) CompareQ
    WHERE JS.state = 1 AND
          JS.job = CompareQ.job AND
          JS.step = CompareQ.step AND
          JS.dependencies < CompareQ.Actual_Dependencies;

    ---------------------------------------------------
    -- Get summary of dependencies for steps
    -- in 'Waiting' state and add to scratch list
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Steplist (job, step, Tool, Priority, Total, Evaluated, Triggered, Shared, signature, Output_Folder_Name,
                                 completion_code, completion_message, evaluation_code, Evaluation_Message)
    SELECT JSD.job,
           JSD.step,
           JS.tool,
           J.priority,
           JS.dependencies AS Total,
           SUM(JSD.evaluated) AS Evaluated,
           SUM(JSD.triggered) AS Triggered,
           JS.shared_result_version AS Shared,
           JS.signature AS Signature,
           JS.output_folder_name,
           JS.completion_code,
           JS.completion_message,
           JS.evaluation_code,
           JS.evaluation_message
    FROM sw.t_job_steps JS
         INNER JOIN sw.t_job_step_dependencies JSD
           ON JSD.job = JS.job AND
              JSD.step = JS.step
         INNER JOIN sw.t_jobs J
           ON JS.job = J.job
    WHERE JS.state = 1
    GROUP BY JSD.job, JSD.step, JS.dependencies,
             JS.shared_result_version, JS.signature,
             J.priority, JS.tool, JS.output_folder_name,
             JS.completion_code, JS.completion_message,
             JS.evaluation_code, JS.evaluation_message
    HAVING JS.dependencies = SUM(JSD.evaluated)
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _candidateStepCount := _insertCount;

    ---------------------------------------------------
    -- Add waiting steps that have no dependencies
    -- to scratch list
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Steplist (job, step, Tool, Priority, Total, Evaluated, Triggered, Shared, signature, Output_Folder_Name,
                              completion_code, completion_message, evaluation_code, Evaluation_Message)
    SELECT JS.job,
           JS.step,
           JS.tool,
           J.priority,
           JS.dependencies AS Total,            -- This will always be zero in this query
           0 AS Evaluated,
           0 AS Triggered,
           JS.shared_result_version AS Shared,
           JS.signature AS Signature,
           JS.output_folder_name,
           JS.completion_code,
           JS.completion_message,
           JS.evaluation_code,
           JS.evaluation_message
    FROM sw.t_job_steps JS
         INNER JOIN sw.t_jobs J
           ON JS.job = J.job
    WHERE JS.state = 1 AND
          JS.dependencies = 0
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _candidateStepCount := _candidateStepCount + _insertCount;

    If _candidateStepCount = 0 Then
        -- Nothing to do
        DROP TABLE Tmp_Steplist;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate the ProcessingOrder column in Tmp_Steplist
    -- Sorting by Priority so that shared steps will tend to be enabled for higher priority jobs first
    ---------------------------------------------------
    --
    UPDATE Tmp_Steplist TargetQ
    SET ProcessingOrder = LookupQ.ProcessingOrder
    FROM ( SELECT EntryID,
                  Row_Number() OVER ( ORDER BY Priority, Job ) AS ProcessingOrder
           FROM Tmp_Steplist
         ) LookupQ
    WHERE TargetQ.EntryID = LookupQ.EntryID;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        SELECT *
        FROM Tmp_Steplist
        ORDER BY ProcessingOrder;
    End If;

    ---------------------------------------------------
    -- Loop through steps in scratch list
    -- check state of their dependencies,
    -- and update their state, as appropriate
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _rowCountToProcess
    FROM Tmp_Steplist

    _rowCountToProcess := Coalesce(_rowCountToProcess, 0);

    WHILE true
    LOOP
        ---------------------------------------------------
        -- Get next step in scratch list
        ---------------------------------------------------

        SELECT
            Job,
            Step,
            Tool,
            Total,
            Evaluated,
            Triggered,
            Shared,
            Signature,
            Output_Folder_Name As OutputFolderName,
            ProcessingOrder,
            Completion_Code As CompletionCode,
            Completion_Message As CompletionMessage,
            Evaluation_Code As EvaluationCode,
            Evaluation_Message As EvaluationMessage
        INTO _stepInfo
        FROM Tmp_Steplist
        WHERE ProcessingOrder > _processingOrder
        ORDER BY ProcessingOrder
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the loop
            EXIT;
        End If;

        ---------------------------------------------------
        -- Job step obtained, process it
        --
        -- If all dependencies for the step are evaluated,
        -- the step's state may be changed
        ---------------------------------------------------
        --
        If _stepInfo.Evaluated = _stepInfo.Total Then
        -- <c>

            ---------------------------------------------------
            -- Get information from parent job
            ---------------------------------------------------
            --
            SELECT dataset, dataset_id
            INTO _dataset, _datasetID
            FROM sw.t_jobs
            WHERE job = _stepInfo.Job;

            ---------------------------------------------------
            -- If any conditional dependencies were triggered,
            -- new state will be 'Skipped'
            -- otherwise, new state will be 'Enabled'
            ---------------------------------------------------
            --
            If _stepInfo.Triggered = 0 Then
                _newState := 2; -- 'Enabled'
            Else
                _newState := 3; -- 'Skipped'
            End If;

            _numCompleted := 0;
            _numPending := 0;

            ---------------------------------------------------
            -- If step has shared results, state change may be affected
            -- Data packaged based jobs cannot have shared results (and will have _datasetID = 0)
            ---------------------------------------------------
            If _stepInfo.Shared <> 0 And _datasetID > 0 Then
            -- <d>

                -- Any standing shared results that match?
                --
                SELECT COUNT(*)
                INTO _numCompleted
                FROM sw.t_shared_results
                WHERE results_name = _stepInfo.OutputFolderName;

                If _numCompleted = 0 Then
                    -- How many current matching shared results steps are in which states?
                    -- A pending step is one that is enabled or running (not failed or holding)
                    --
                    SELECT Coalesce(SUM(CASE WHEN state = 5 THEN 1 ELSE 0 END), 0),
                           Coalesce(SUM(CASE WHEN state IN (2, 4, 9) THEN 1 ELSE 0 END), 0)
                    INTO _numCompleted, _numPending
                    FROM sw.t_job_steps
                    WHERE output_folder_name = _stepInfo.OutputFolderName AND
                          NOT output_folder_name IS NULL;

                    If _numCompleted = 0 Then
                        -- Also check sw.t_job_steps_history for completed, matching shared results steps
                        --
                        -- Old, completed jobs are removed from sw.t_jobs after a set number of days, meaning it's possible
                        -- that the only record of a completed, matching shared results step will be in sw.t_job_steps_history

                        SELECT COUNT(*)
                        INTO _numCompleted
                        FROM sw.t_job_steps_history
                        WHERE output_folder_name = _stepInfo.OutputFolderName AND
                              NOT output_folder_name IS NULL AND
                              state = 5;
                    End If;

                    --
                    -- If there were any completed shared results not already in
                    -- standing shared results table, make entry in shared results
                    --
                    If _numCompleted > 0 Then
                        If _infoOnly Then
                            RAISE INFO 'Insert "%" into sw.t_shared_results', _stepInfo.OutputFolderName;
                        Else
                            INSERT INTO sw.t_shared_results( results_name )
                            VALUES (_stepInfo.OutputFolderName)
                        End If;
                    End If;
                End If;

                -- Skip this step if another step has already created the shared results
                -- Otherwise, continue waiting if another step is making the shared results
                --  (the other step will either succeed or fail, and then this step's action will be re-evaluated)
                --
                If _numCompleted > 0 Then
                    -- Check for whether this step has been skipped numerous times in the last 12 hours
                    -- If it has, this indicates that the database metadata for this dataset's other jobs indicates that the step can be skipped,
                    -- but a subsequent step is not finding the shared results and they need to be re-generated

                    SELECT COUNT(*)
                    INTO _stepSkipCount
                    FROM sw.t_job_step_events
                    WHERE job = _stepInfo.job AND
                          step = _stepInfo.step AND
                          prev_target_state = 1 AND
                          target_state = 3 AND
                          entered >= CURRENT_TIMESTAMP - INTERVAL '12 hours';

                    If _stepSkipCount >= 15 Then
                        _msg := format('Job %s, step %s has been skipped %s times in the last 12 hours; setting the step state to 2 to allow results to be regenerated',
                                        _stepInfo.job , _stepInfo.step, _stepSkipCount);

                        If _infoOnly Then
                            RAISE INFO '%', _msg;
                        Else
                            CALL public.post_log_entry ('Warning', _msg, 'Update_Dependent_Steps', 'sw');
                        End If;

                        _newState := 2      ; -- 'Enabled'
                    Else
                        _newState := 3      ; -- 'Skipped'
                    End If;
                Else
                    If _numPending > 0 Then
                        _newState := 1  ; -- 'Waiting'
                    End If;
                End If;

            End If; -- </d>

            If _infoOnly Then

                RAISE INFO 'Job %, step %, _outputFolderName %, _numCompleted %, _numPending %, _newState %',
                            _stepInfo.job, _stepInfo.step, _stepInfo.outputFolderName, _numCompleted, _numPending, _newState;
            End If;

            ---------------------------------------------------
            -- If step state needs to be changed, update step
            ---------------------------------------------------
            --
            If _newState <> 1 Then
            -- <e>

                ---------------------------------------------------
                -- Update step state and output folder name
                -- (input folder name is passed through if step is skipped,
                -- unless the tool is DTA_Refinery or Mz_Refinery or ProMex, then the folder name is
                -- NOT passed through if the tool is skipped)
                ---------------------------------------------------
                --
                If _infoOnly Then
                    RAISE INFO 'Update state in sw.t_job_steps for job %, step % from 1 to %',_stepInfo.job, _stepInfo.step, _newState;
                Else
                    -- The update query below sets Completion_Code to 0 and clears Completion_Message
                    -- If the job step currently has a completion code and/or message, store it in the evaluation message

                    -- This could arise if a job step with shared results was skipped  (e.g. step 2),
                    -- then a subsequent job step could not find the shared results (e.g. step 3)
                    -- and the analysis manager updates the shared result step's state to 2 (enabled),
                    -- then step 2 runs, but fails and has its state set back to 1 (waiting),
                    -- then it is skipped again (via update logic defined earlier in this procedure),
                    -- then the subsequent step (step 3) runs again, and this time the shared results were able to be found and it thus succeeds.

                    -- In this scenario (which happened with job 2010021), we do not want the completion message to have any text,
                    -- since we don't want that text to end up in the job comment in the primary job table (T_Analysis_Job).

                    _newEvaluationMessage := Coalesce(_stepInfo.evaluationMessage, '');

                    If _stepInfo.completionCode > 0 Then
                        _newEvaluationMessage := public.append_to_text(_newEvaluationMessage, format('Original completion code: %s', _stepInfo.completionCode), 0, '; ', 512);
                    End If;

                    If Coalesce(_stepInfo.completionMessage, '') <> '' Then
                        _newEvaluationMessage := public.append_to_text(_newEvaluationMessage, format('Original completion msg: %s', _stepInfo.completionMessage), 0, '; ', 512);
                    End If;

                    -- This query updates the state to _newState
                    -- It may also update Output_Folder_Name; here's the logic:
                        -- If the new state is not 3 (skipped), will leave Output_Folder_Name unchanged
                        -- If the new state is 3, change Output_Folder_Name to be Input_Folder_Name, but only if:
                        --  a. the step tool is not DTA_Refinery or Mz_Refinery or ProMex and
                        --  b. the Input_Folder_Name is not blank (this check is needed when the first step of a job
                        --     is skipped; that step will always have a blank Input_Folder_Name, and we don't want
                        --     the Output_Folder_Name to get blank'd out)

                    UPDATE sw.t_job_steps
                    SET state = _newState,
                        output_folder_name =
                          CASE WHEN (_newState = 3 AND
                                    Coalesce(input_folder_name, '') <> '' AND
                                    tool NOT IN ( SELECT step_tool
                                                  FROM sw.t_step_tools
                                                  WHERE shared_result_version > 0 AND
                                                        disable_output_folder_name_override_on_skip > 0 )
                                    )
                               THEN input_folder_name
                               ELSE Output_Folder_Name
                          End,
                          Completion_Code = 0,
                          Completion_Message = '',
                          Evaluation_Message = _newEvaluationMessage
                    WHERE Job = _stepInfo.job AND
                          Step = _stepInfo.step AND
                          State = 1;       -- Assure that we only update steps in state 1=waiting

                End If;

                _numStepsUpdated := _numStepsUpdated + 1;

                -- Bump _numStepsSkipped for each skipped step
                If _newState = 3 Then
                    _numStepsSkipped := _numStepsSkipped + 1;
                End If;
            End If; -- </e>

        End If; -- </c>

        _rowsProcessed := _rowsProcessed + 1;

        If extract(epoch FROM (clock_timestamp() - _lastLogTime)) >= _loopingUpdateInterval Then
            _statusMessage := format('... Updating dependent steps: %s / %s', _rowsProcessed, _rowCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Dependent_Steps', 'sw');
            _lastLogTime := clock_timestamp();
        End If;

        If _maxJobsToProcess > 0 Then
            SELECT COUNT(DISTINCT Job)
            INTO _jobCount
            FROM Tmp_Steplist
            WHERE ProcessingOrder <= _processingOrder;

            If Coalesce(_jobCount, 0) >= _maxJobsToProcess Then
                -- Break out of the While Loop
                EXIT;
            End If;
        End If;

    END LOOP;

    If _infoOnly Then
        RAISE INFO 'Steps updated: %', _numStepsUpdated;
        RAISE INFO 'Steps set to state 3 (skipped): %', _numStepsSkipped;
    End If;

    DROP TABLE Tmp_Steplist;
END
$$;

COMMENT ON PROCEDURE sw.update_dependent_steps IS 'UpdateDependentSteps';
