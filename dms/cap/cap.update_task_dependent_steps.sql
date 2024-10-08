--
-- Name: update_task_dependent_steps(text, text, integer, boolean, integer, integer); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_task_dependent_steps(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, INOUT _numstepsskipped integer DEFAULT 0, IN _infoonly boolean DEFAULT false, IN _maxjobstoprocess integer DEFAULT 0, IN _loopingupdateinterval integer DEFAULT 10)
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
**    _message                  Status message
**    _returnCode               Return code
**    _numStepsSkipped          Output: number of skipped steps
**    _infoOnly                 True to preview changes that would be made
**    _maxJobsToProcess         Maximum number of jobs to process
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/25/2011 mem - Now using the Priority column from t_tasks
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          03/10/2015 mem - Now updating t_task_steps.Dependencies if the dependency count listed is lower than that defined in t_task_step_dependencies
**          06/20/2023 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(job) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          08/27/2024 mem - Change default value for _loopingUpdateInterval to 10 seconds (previously 5 seconds)
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _newState int;

    _stepInfo record;
    _candidateStepCount int;
    _numStepsUpdated int;

    _lastLogTime timestamp;
    _statusMessage text;
    _rowCountToProcess int;
    _rowsProcessed int;
BEGIN
    _message := '';
    _returnCode := '';

    _numStepsSkipped := 0;
    _numStepsUpdated := 0;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly              := Coalesce(_infoOnly, false);
    _maxJobsToProcess      := Coalesce(_maxJobsToProcess, 0);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 10);

    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    ---------------------------------------------------
    -- Temp table to hold scratch list of step dependencies
    ---------------------------------------------------

    CREATE TEMP TABLE T_Tmp_Steplist (
        Job int,
        Step int,
        Tool text,
        Priority int,                                -- Holds capture task job priority
        Total int,
        Evaluated int,
        Triggered int,
        Shared int,
        Signature int,
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Output_Folder_Name text NULL,
        ProcessingOrder int NULL                    -- We will populate this column after the T_Tmp_Steplist table gets populated
    );

    CREATE INDEX IX_StepList_ProcessingOrder ON T_Tmp_Steplist (ProcessingOrder, Job);

    ---------------------------------------------------
    -- Bump up the value for Dependencies in t_task_steps if it is too low
    -- This will happen if new rows are manually added to t_task_step_dependencies
    ---------------------------------------------------

    UPDATE cap.t_task_steps TS
    SET Dependencies = CompareQ.Actual_Dependencies
    FROM (SELECT SD.Job,
                 SD.Step,
                 COUNT(job) AS Actual_Dependencies
          FROM cap.t_task_step_dependencies SD
          WHERE SD.Job IN (SELECT W.Job FROM cap.t_task_steps W WHERE W.State = 1)   -- State 1=Waiting
          GROUP BY SD.Job, SD.Step
         ) CompareQ
    WHERE TS.State = 1 AND
          TS.Job = CompareQ.Job AND
          TS.Step = CompareQ.Step AND
          TS.Dependencies < CompareQ.Actual_Dependencies;

    ---------------------------------------------------
    -- Get summary of dependencies for steps
    -- in 'Waiting' state and add to scratch list
    ---------------------------------------------------

    INSERT INTO T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Output_Folder_Name)
    SELECT TSD.Job,
           TSD.Step AS Step,
           TS.Tool,
           T.Priority,
           TS.Dependencies AS Total,
           SUM(TSD.Evaluated) AS Evaluated,
           SUM(TSD.Triggered) AS Triggered,
           Output_Folder_Name
    FROM cap.t_task_steps TS
         INNER JOIN cap.t_task_step_dependencies TSD
           ON TSD.Job = TS.Job AND
              TSD.Step = TS.Step
         INNER JOIN cap.t_tasks T
           ON TS.Job = T.Job
    WHERE TS.State = 1
    GROUP BY TSD.Job, TSD.Step, TS.Dependencies,
             T.Priority, TS.Tool, TS.Output_Folder_Name
    HAVING TS.Dependencies = SUM(TSD.Evaluated);
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    _candidateStepCount := _matchCount;

    ---------------------------------------------------
    -- Add waiting steps that have no dependencies
    -- to scratch list
    ---------------------------------------------------

    INSERT INTO T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Output_Folder_Name)
    SELECT TS.Job,
           TS.Step,
           TS.Tool,
           T.Priority,
           TS.Dependencies AS Total,            -- This will always be zero in this query
           0 AS Evaluated,
           0 AS Triggered,
           TS.Output_Folder_Name
    FROM cap.t_task_steps TS
         INNER JOIN cap.t_tasks T
           ON TS.Job = T.Job
    WHERE TS.State = 1 AND
          TS.Dependencies = 0;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    _candidateStepCount := _candidateStepCount + _matchCount;

    If _candidateStepCount = 0 Then
        -- Nothing to do
        DROP TABLE T_Tmp_Steplist;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate the ProcessingOrder column in T_Tmp_Steplist
    -- Sorting by Priority so that shared steps will tend to be enabled for higher priority capture task jobs first
    ---------------------------------------------------

    UPDATE T_Tmp_Steplist TargetQ
    SET ProcessingOrder = LookupQ.ProcessingOrder
    FROM (SELECT TS.EntryID,
                 Row_Number() OVER (ORDER BY TS.Priority, TS.Job) AS ProcessingOrder
          FROM T_Tmp_Steplist TS
         ) LookupQ
    WHERE TargetQ.EntryID = LookupQ.EntryID;

    ---------------------------------------------------
    -- Loop through steps in scratch list
    -- check state of their dependencies,
    -- and update their state, as appropriate
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _rowCountToProcess
    FROM T_Tmp_Steplist;

    _rowCountToProcess := Coalesce(_rowCountToProcess, 0);

    _rowsProcessed := 0;
    _lastLogTime := clock_timestamp();

    FOR _stepInfo IN
        SELECT Job,
               Step,
               Tool,
               Total,
               Evaluated,
               Triggered,
               Shared,
               Signature,
               Output_Folder_Name,
               ProcessingOrder
        FROM T_Tmp_Steplist
        ORDER BY ProcessingOrder
    LOOP
        If _stepInfo.Evaluated <> _stepInfo.Total Then
            CONTINUE;
        End If;

        ---------------------------------------------------
        -- All dependencies for the step are evaluated;
        -- the step's state may be changed
        ---------------------------------------------------

        ---------------------------------------------------
        -- If any conditional dependencies were triggered, new state will be 'Skipped'
        -- Otherwise, new state will be 'Enabled'
        ---------------------------------------------------

        If _stepInfo.Triggered = 0 Then
            _newState := 2; -- 'Enabled'
        Else
            _newState := 3; -- 'Skipped'
        End If;

        /*
         * Hold off enable of archive update based on pending dataset archive
         *

            ---------------------------------------------------
            -- If step has shared results, state change may be affected
            ---------------------------------------------------

            If _stepInfo.Shared <> 0 Then

                -- Any standing shared results that match?

                SELECT COUNT(results_name)
                INTO _numCompleted
                FROM cap.t_shared_results
                WHERE results_name = _outputFolderName;

                If Coalesce(_numCompleted, 0) = 0 Then

                    -- How many current matching shared results steps are in which states?

                    SELECT Coalesce(SUM(CASE WHEN State = 5 THEN 1 ELSE 0 END), 0),
                           Coalesce(SUM(CASE WHEN State in (2, 4) THEN 1 ELSE 0 END), 0)
                    INTO _numCompleted, _numPending
                    FROM cap.t_task_steps
                    WHERE Output_Folder_Name = _outputFolderName AND
                          NOT Output_Folder_Name IS NULL AND
                          State IN (2, 4, 5);

                    If Coalesce(_numCompleted, 0) = 0 Then
                        -- Also check t_task_steps_history for completed, matching shared results steps

                        -- Old, completed capture task jobs are removed from t_tasks after a set number of days, meaning it's possible
                        -- that the only record of a completed, matching shared results step will be in t_task_steps_history

                        SELECT COUNT(job)
                        INTO _numCompleted
                        FROM cap.t_task_steps_history
                        WHERE Output_Folder_Name = _outputFolderName AND
                              NOT Output_Folder_Name IS NULL AND
                              State = 5;

                    End If;

                    -- If there were any completed shared results not already in
                    -- standing shared results table, make entry in shared results

                    If Coalesce(_numCompleted, 0) > 0 Then
                        If _infoOnly Then
                            RAISE INFO ', 'Insert "%" into T_Shared_Results', _outputFolderName;
                        Else
                            INSERT INTO T_Shared_Results (Results_Name)
                            VALUES (_outputFolderName);
                        End If;
                    End If;
                End If;

                -- Skip if another step has already created the shared results
                -- Otherwise, continue waiting if another step is making the shared results
                --  (the other step will either succeed or fail, and then this step's action will be re-evaluated)

                If Coalesce(_numCompleted, 0) > 0 Then
                    _newState := 3; -- 'Skipped'
                Else
                    If _numPending > 0 Then
                        _newState := 1; -- 'Waiting'
                    End If;
                End If;

            End If;

         */

        ---------------------------------------------------
        -- If step state needs to be changed, update step
        ---------------------------------------------------

        If _newState <> 1 Then
            ---------------------------------------------------
            -- Update step state and output folder name
            -- (input folder name is passed through if step is skipped)
            ---------------------------------------------------

            If _infoOnly Then
                RAISE INFO 'Update state in cap.t_task_steps for capture task job %, step %, from 1 to %', _stepInfo.Job, _stepInfo.Step, _newState;
            Else
                UPDATE cap.t_task_steps
                SET State = _newState,
                    Output_Folder_Name = CASE
                                             WHEN _newState = 3 AND Coalesce(Input_Folder_Name, '') <> ''
                                             THEN Input_Folder_Name
                                             ELSE Output_Folder_Name
                                         END
                WHERE Job = _stepInfo.Job AND
                      Step = _stepInfo.Step AND
                      State = 1;        -- Assure that we only update steps in state 1=waiting
            End If;

            _numStepsUpdated := _numStepsUpdated + 1;

            -- Bump _numStepsSkipped for each step skipped
            If _newState = 3 Then
                _numStepsSkipped := _numStepsSkipped + 1;
            End If;

        End If;

        _rowsProcessed := _rowsProcessed + 1;

        If Extract(epoch from clock_timestamp() - _lastLogTime) >= _loopingUpdateInterval Then
            _statusMessage := format('... Updating dependent steps: %s / %s', _rowsProcessed, _rowCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_Dependent_Steps', 'cap');

            _lastLogTime := clock_timestamp();
        End If;

        If _maxJobsToProcess > 0 Then
            SELECT COUNT(DISTINCT Job)
            INTO _matchCount
            FROM T_Tmp_Steplist
            WHERE ProcessingOrder <= _stepInfo.ProcessingOrder;

            If Coalesce(_matchCount, 0) >= _maxJobsToProcess Then
                -- Break out of the for loop
                EXIT;
            End If;
        End If;

    END LOOP;

    If _infoOnly Then
        RAISE INFO 'Steps updated: %', _numStepsUpdated;
        RAISE INFO 'Steps set to state 3 (skipped): %', _numStepsSkipped;
    End If;

    DROP TABLE T_Tmp_Steplist;

END
$$;


ALTER PROCEDURE cap.update_task_dependent_steps(INOUT _message text, INOUT _returncode text, INOUT _numstepsskipped integer, IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer) OWNER TO d3l243;

--
-- Name: PROCEDURE update_task_dependent_steps(INOUT _message text, INOUT _returncode text, INOUT _numstepsskipped integer, IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_task_dependent_steps(INOUT _message text, INOUT _returncode text, INOUT _numstepsskipped integer, IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer) IS 'UpdateTaskDependentSteps or UpdateDependentSteps';

