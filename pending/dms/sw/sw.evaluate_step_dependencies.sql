--
CREATE OR REPLACE PROCEDURE sw.evaluate_step_dependencies
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _maxJobsToProcess int = 0,
    _loopingUpdateInterval int = 5,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Look at all unevaluated dependentices for steps
**      that are finised (completed or skipped) and evaluate them
**
**  Arguments:
**    _loopingUpdateInterval   Seconds between detailed logging while looping through the dependencies
**
**  Auth:   grk
**  Date:   05/06/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/06/2009 grk - added condition evaluation logic for Completion_Message_Contains http://prismtrac.pnl.gov/trac/ticket/706.
**          06/01/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter _loopingUpdateInterval
**          12/21/2009 mem - Added parameter _infoOnly
**          12/20/2011 mem - Changed _message to an optional output parameter
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          03/30/2018 mem - Rename variables and reformat queries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _startTime timestamp;
    _statusMessage text;
    _rowCountToProcess int;
    _sortOrder int;
    _job int;
    _dependentStep int;
    _targetStep int;
    _targetState int;
    _targetCompletionCode int;
    _targetCompletionMessage citext;
    _condition_Test citext;
    _testValue citext;
    _triggered boolean;
    _actualValue int;
    _enableOnly int;
    _rowsProcessed int := 0;
    _lastLogTime timestamp := CURRENT_TIMESTAMP;
    _outputFolderName text := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    _message := '';
    _returnCode:= '';
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    _startTime := CURRENT_TIMESTAMP;
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);
    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    ---------------------------------------------------
    -- Temp table for processing dependenices
    ---------------------------------------------------
    CREATE TEMP TABLE Tmp_DepTable (
        Job int,
        DependentStep int,
        TargetStep int,
        TargetState int,
        TargetCompletionCode int,
        Condition_Test text,
        Test_Value text,
        Enable_Only int,
        SortOrder int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    )

    CREATE INDEX IX_Tmp_DepTable_SortOrder ON Tmp_DepTable (SortOrder);

    ---------------------------------------------------
    -- For steps that are waiting,
    -- get unevaluated dependencies that target steps
    -- that are finished (skipped or completed)
    ---------------------------------------------------
    --
    INSERT INTO Tmp_DepTable (
        job,
        DependentStep,
        TargetStep,
        TargetState,
        TargetCompletionCode,
        condition_test,
        test_value,
        enable_only
    )
    SELECT JS.job,
           JSD.step AS DependentStep,
           JS.step AS TargetStep,
           JS.state AS TargetState,
           JS.completion_code AS TargetCompletionCode,
           JSD.condition_test,
           JSD.test_value,
           JSD.enable_only
    FROM sw.t_job_step_dependencies JSD
         INNER JOIN sw.t_job_steps JS
           ON JSD.target_step = JS.step AND
              JSD.job = JS.job
         INNER JOIN sw.t_job_steps AS JS_B
           ON JSD.job = JS_B.job AND
              JSD.step = JS_B.step
    WHERE (JSD.evaluated = 0) AND
          (JS.state IN (3, 5)) AND
          (JS_B.state = 1);
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Nothing found, nothing to process
    If _myRowCount = 0 Then
        If _infoOnly Then
            RAISE INFO 'Did not find any job steps to process';
        End If;

        DROP TABLE Tmp_DepTable;
        RETURN;
    End If;

    If _maxJobsToProcess > 0 Then
        -- Limit the number of jobs to evaluate
        DELETE FROM Tmp_DepTable
        WHERE NOT Job IN ( SELECT TOP ( _maxJobsToProcess ) Job
                           FROM Tmp_DepTable
                           ORDER BY Job )

    End If;

    If _infoOnly Then

            -- ToDo: Update this to use RAISE INFO

        -- Preview the steps to process
        SELECT *
        FROM Tmp_DepTable
        ORDER BY SortOrder
    End If;

    ---------------------------------------------------
    -- Loop though dependencies and evaluate them
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _rowCountToProcess
    FROM Tmp_DepTable

    _rowCountToProcess := Coalesce(_rowCountToProcess, 0);

    _sortOrder := -1;

    WHILE true
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
               Condition_Test,
               Test_Value,
               Enable_Only
        INTO _sortOrder, _job, _dependentStep, _targetStep, _targetState, _targetCompletionCode, _condition_Test, _testValue, _enableOnly
        FROM Tmp_DepTable
        WHERE SortOrder > _sortOrder
        ORDER BY SortOrder
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        ---------------------------------------------------
        -- Evaluate dependency condition (if one is defined)
        ---------------------------------------------------
        --
        _triggered := false;

        ---------------------------------------------------
        -- Skip if signature of dependent step matches
        -- test value (usually used with value of '0'
        -- which happens when there are no parameters)
        --
        If _condition_Test = 'No_Parameters' Then
            -- Get filter signature for dependent step
            --
            SELECT signature
            INTO _actualValue
            FROM sw.t_job_steps
            WHERE job = _job AND
                  step = _dependentStep;

            If Not FOUND Then
                _message := format('Error getting dependent step filter signature: step %s for job %s not found in t_job_steps', _dependentStep, _job);
                _returnCode = 'U5431';

                DROP TABLE Tmp_DepTable;
                RETURN;
            End If;

            If _actualValue = 0 Then
                _triggered := true;
            End If;

        End If;

        ---------------------------------------------------
        -- Skip if state of target step
        -- is skipped
        --
        If _condition_Test = 'Target_Skipped' Then
            -- Get shared result setting for target step
            --
            SELECT state
            INTO _actualValue
            FROM sw.t_job_steps
            WHERE job = _job AND
                  step = _targetStep;

            If Not FOUND Then
                _message := format('Error getting target step state: step %s for job %s not found in t_job_steps', _targetStep, _job);
                _returnCode = 'U5432';

                DROP TABLE Tmp_DepTable;
                RETURN;
            End If;

            If _actualValue = 3 Then
                _triggered := true;
            End If;
        End If;

        ---------------------------------------------------
        -- Skip if completion message of target step
        -- contains test value
        --
        If _condition_Test = 'Completion_Message_Contains' Then
            -- Get completion message for target step
            --
            SELECT completion_message
            INTO _targetCompletionMessage
            FROM sw.t_job_steps
            WHERE job = _job AND
                  step = _targetStep

            If FOUND And _targetCompletionMessage Like ('%' || _testValue || '%')::citext Then
                _triggered := true;
            End If;
        End If;

        If _infoOnly And Coalesce(_condition_Test, '') <> '' Then
            RAISE INFO 'Dependent Step %, Target Step %, Condition Test %; Triggered = %',_dependentStep, _targetStep, _condition_Test, _triggered;
        End If;

        ---------------------------------------------------
        -- Copy output folder from target step
        -- to be input folder for dependent step
        -- unless dependency is 'Enable_Only'
        ---------------------------------------------------
        --
        If _enableOnly = 0 Then

            SELECT output_folder_name
            INTO _outputFolderName
            FROM sw.t_job_steps
            WHERE job = _job AND step = _targetStep

            If _infoOnly Then
                RAISE INFO 'Update Job %, step % to have Input_Folder_Name = "%"', _job, _dependentStep, _outputFolderName;
            Else
                UPDATE sw.t_job_steps
                SET Input_Folder_Name = _outputFolderName
                WHERE Job = _job AND
                      Step = _dependentStep;
            End If;

        End If;

        ---------------------------------------------------
        -- Update state of dependency
        ---------------------------------------------------
        --
        If _infoOnly Then
            RAISE INFO 'Update job %, step % with target step % to have evaluated=1 and triggered= % in table sw.t_job_step_dependencies',
                          _job, _dependentStep, _targetStep, _triggered;
        Else
            UPDATE sw.t_job_step_dependencies;
            SET Evaluated = 1,
                Triggered = CASE WHEN _triggered THEN 1 ELSE 0 END
            WHERE Job = _job AND
                  Step = _dependentStep AND
                  Target_Step = _targetStep;
        End If;

        _rowsProcessed := _rowsProcessed + 1;

        If extract(epoch FROM (clock_timestamp() - _lastLogTime)) >= _loopingUpdateInterval Then

            _statusMessage := format('... Evaluating step dependencies: %s / %s', _rowsProcessed, _rowCountToProcess);
            Call public.post_log_entry ('Progress', _statusMessage, 'Evaluate_Step_Dependencies', 'sw');

            _lastLogTime := clock_timestamp();
        End If;

    END LOOP;

    DROP TABLE Tmp_DepTable;

END
$$;

COMMENT ON PROCEDURE sw.evaluate_step_dependencies IS 'EvaluateStepDependencies';
