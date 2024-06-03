--
-- Name: evaluate_task_step_dependencies(text, text, integer, integer, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.evaluate_task_step_dependencies(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _maxjobstoprocess integer DEFAULT 0, IN _loopingupdateinterval integer DEFAULT 5, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look at all unevaluated dependencies for steps that are finished (completed or skipped)
**      and evaluate them
**
**  Arguments:
**    _message                  Status message
**    _returnCode               Return code
**    _maxJobsToProcess         Maximum number of jobs to process (0 to process all)
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**    _showDebug                When true, show status messages
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/17/2019 mem - Switch from folder to directory
**          06/01/2020 mem - Add support for step state 13 (Inactive)
**          10/11/2022 mem - Ported to PostgreSQL
**          11/30/2022 mem - Use clock_timestamp() when determining elapsed runtime
**          02/02/2023 mem - Update table aliases
**          04/02/2023 mem - Rename procedure and functions
**          04/27/2023 mem - Use boolean for data type name
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          06/20/2023 mem - Remove unused variable
**          07/11/2023 mem - Use COUNT(Job) instead of COUNT(*)
**          07/26/2023 mem - Move "Not" keyword to before the field name
**          09/07/2023 mem - Align assignment statements
**          01/03/2024 mem - Update warning message
**
*****************************************************/
DECLARE
    _lastLogTime timestamp;
    _statusMessage text;
    _rowCountToProcess int;
    _rowsProcessed int;
    _stepInfo record;
    _triggered int;
    _actualValue int;
    _done boolean;
    _outputDirectoryName text;
    _targetCompletionMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _maxJobsToProcess      := Coalesce(_maxJobsToProcess, 0);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);
    _showDebug             := Coalesce(_showDebug, false);

    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    If _showDebug Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Temporary table for processing dependencies
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DepTable (
        Job int,
        DependentStep int,
        TargetStep int,
        TargetState int,
        TargetCompletionCode int,
        ConditionTest text,
        TestValue text,
        EnableOnly int,
        SortOrder int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    CREATE INDEX IX_Tmp_DepTable_SortOrder ON Tmp_DepTable (SortOrder);

    ---------------------------------------------------
    -- For steps that are waiting,
    -- get unevaluated dependencies that target steps
    -- that are finished (skipped or completed)
    ---------------------------------------------------

    INSERT INTO Tmp_DepTable (
        Job,
        DependentStep,
        TargetStep,
        TargetState,
        TargetCompletionCode,
        ConditionTest,
        TestValue,
        EnableOnly
    )
    SELECT TS.Job,
           TSD.Step AS DependentStep,
           TS.Step AS TargetStep,
           TS.State AS TargetState,
           TS.Completion_Code AS TargetCompletionCode,
           TSD.Condition_Test,
           TSD.Test_Value,
           TSD.Enable_Only
    FROM cap.t_task_step_dependencies TSD
         INNER JOIN cap.t_task_steps TS
           ON TSD.Target_Step = TS.Step AND
              TSD.Job = TS.Job
         INNER JOIN cap.t_task_steps AS TS_B
           ON TSD.Job = TS_B.Job AND
              TSD.Step = TS_B.Step
    WHERE TSD.Evaluated = 0 AND
          TS.State IN (3, 5, 13) AND
          TS_B.State = 1;

    If Not FOUND Then
        -- Nothing found, nothing to process
        If _showDebug Then
            RAISE INFO 'Did not find any capture task job steps with a completed parent step in t_task_steps and Evaluated = 0 in t_task_step_dependencies';
        End If;

        DROP TABLE Tmp_DepTable;
        RETURN;
    End If;

    If _maxJobsToProcess > 0 Then
        -- Limit the number of capture task jobs to evaluate
        DELETE FROM Tmp_DepTable
        WHERE NOT Job IN (SELECT Job
                          FROM Tmp_DepTable
                          ORDER BY Job
                          LIMIT _maxJobsToProcess);

    End If;

    ---------------------------------------------------
    -- Loop though dependencies and evaluate them
    ---------------------------------------------------

    SELECT COUNT(job)
    INTO _rowCountToProcess
    FROM Tmp_DepTable;

    _rowCountToProcess := Coalesce(_rowCountToProcess, 0);

    If _showDebug Then
        RAISE INFO 'Found % % to process', _rowCountToProcess, public.check_plural(_rowCountToProcess, 'step', 'steps');
    End If;

    _done := false;
    _rowsProcessed := 0;
    _lastLogTime := clock_timestamp();

    WHILE Not _done
    LOOP
        ---------------------------------------------------
        -- Get next step dependency
        ---------------------------------------------------

        SELECT SortOrder,
               Job,
               DependentStep,
               TargetStep,
               TargetState,
               TargetCompletionCode,
               ConditionTest,
               TestValue,
               EnableOnly
        INTO _stepInfo
        FROM Tmp_DepTable
        ORDER BY SortOrder
        LIMIT 1;

        If Not FOUND Then
            _done := true;
        Else
            ---------------------------------------------------
            -- Evaluate dependency condition (if one is defined)
            ---------------------------------------------------

            If _showDebug Then
                RAISE INFO 'Evaluating job %, step %, which is triggered after step % completes', _stepInfo.Job, _stepInfo.DependentStep, _stepInfo.TargetStep;
            End If;

            _triggered := 0;
/*
            -- Skip if signature of dependent step matches
            -- test value (usually used with value of "0"
            -- which happens when there are no parameters)

            If _stepInfo.ConditionTest = 'No_Parameters' Then
                -- get filter signature for dependent step

                _actualValue := -1;

                SELECT Signature
                INTO _actualValue
                FROM cap.t_task_steps
                WHERE Job = _stepInfo.Job AND Step = _stepInfo.DependentStep

                If _actualValue = -1 Then
                    _message := 'Error getting filter signature';
                    _returnCode := 'U5201';

                    DROP TABLE Tmp_DepTable;
                    RETURN;
                End If;

                If _actualValue = 0 Then
                    _triggered := 1;
                End If;
            Else
*/

            -- Skip if state of target step
            -- is skipped

            If _stepInfo.ConditionTest = 'Target_Skipped' Then

                -- Get shared result setting for target step

                SELECT State
                INTO _actualValue
                FROM cap.t_task_steps
                WHERE Job = _stepInfo.Job AND Step = _stepInfo.TargetStep;

                If Not FOUND Then
                    _message := format('Error getting state for job %s, step %s', _stepInfo.Job, _stepInfo.TargetStep);
                    _returnCode := 'U5202';

                    RAISE WARNING '%', _message;

                    DROP TABLE Tmp_DepTable;
                    RETURN;
                End If;

                If _actualValue = 3 Then
                    If _showDebug Then
                        RAISE INFO 'For job %, step % was skipped; setting triggered to 1 for step %', _stepInfo.Job, _stepInfo.TargetStep, _stepInfo.DependentStep;
                    End If;

                    _triggered := 1;
                End If;

            End If;

            -- Skip if completion message of target step
            -- contains test value

            If _stepInfo.ConditionTest = 'Completion_Message_Contains' Then

                -- Get completion message for target step

                SELECT Completion_Message
                INTO _targetCompletionMessage
                FROM cap.t_task_steps
                WHERE Job = _stepInfo.Job AND Step = _stepInfo.TargetStep;

                If FOUND And _targetCompletionMessage LIKE '%' || _stepInfo.TestValue || '%' Then
                    If _showDebug Then
                        RAISE INFO 'For job %, step % has a completion message that contains "%"; setting triggered to 1 for step %',
                                    _stepInfo.Job, _stepInfo.TargetStep, _stepInfo.TestValue, _stepInfo.DependentStep;
                    End If;

                    _triggered := 1;
                End If;
            End If;

            -- FUTURE: more conditions here

            ---------------------------------------------------
            -- Copy output directory from target step
            -- to input directory for dependent step,
            -- unless dependency is "Enable_Only"
            ---------------------------------------------------

            If _stepInfo.EnableOnly = 0 Then

                SELECT Output_Folder_Name
                INTO _outputDirectoryName
                FROM cap.t_task_steps
                WHERE Job = _stepInfo.Job AND Step = _stepInfo.TargetStep;

                UPDATE cap.t_task_steps
                SET Input_Folder_Name = _outputDirectoryName
                WHERE Job = _stepInfo.Job AND Step = _stepInfo.DependentStep;

            End If;

            ---------------------------------------------------
            -- Update state of dependency
            ---------------------------------------------------

            UPDATE cap.t_task_step_dependencies
            SET Evaluated = 1,
                Triggered = _triggered
            WHERE Job = _stepInfo.Job AND
                  Step = _stepInfo.DependentStep AND
                  Target_Step = _stepInfo.TargetStep;

            If _showDebug Then
                RAISE INFO 'Set evaluated to 1 and triggered to % for job %, step %', _triggered, _stepInfo.Job, _stepInfo.DependentStep;
            End If;

            ---------------------------------------------------
            -- Remove dependency from processing table
            ---------------------------------------------------

            DELETE FROM Tmp_DepTable
            WHERE SortOrder = _stepInfo.SortOrder;

            _rowsProcessed := _rowsProcessed + 1;
        End If;

        If Extract(epoch from clock_timestamp() - _lastLogTime) >= _loopingUpdateInterval Then
            _statusMessage := format('... Evaluating step dependencies: %s / %s', _rowsProcessed, _rowCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Evaluate_Task_Step_Dependencies', 'cap');

            _lastLogTime := clock_timestamp();
        End If;

    END LOOP;

    DROP TABLE Tmp_DepTable;

END
$$;


ALTER PROCEDURE cap.evaluate_task_step_dependencies(INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE evaluate_task_step_dependencies(INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _showdebug boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.evaluate_task_step_dependencies(INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _showdebug boolean) IS 'EvaluateStepDependencies';

