--
-- Name: evaluate_step_dependencies(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.evaluate_step_dependencies(IN _maxjobstoprocess integer DEFAULT 0, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look at all unevaluated dependencies for steps
**      that are finised (completed or skipped) and evaluate them
**
**  Arguments:
**    _maxJobsToProcess         Maximum number of jobs to process (0 to process all)
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**    _infoOnly                 When true, preview updates
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   05/06/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/06/2009 grk - Added condition evaluation logic for Completion_Message_Contains http://prismtrac.pnl.gov/trac/ticket/706.
**          06/01/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter _loopingUpdateInterval
**          12/21/2009 mem - Added parameter _infoOnly
**          12/20/2011 mem - Changed _message to an optional output parameter
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          03/30/2018 mem - Rename variables and reformat queries
**          08/02/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
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

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _maxJobsToProcess      := Coalesce(_maxJobsToProcess, 0);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    _startTime := CURRENT_TIMESTAMP;

    ---------------------------------------------------
    -- Temp table for processing dependencies
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DepTable (
        Job int,
        Dependent_Step int,
        Target_Step int,
        Target_State int,
        Target_Completion_Code int,
        Condition_Test text,
        Test_Value text,
        Enable_Only int,
        Sort_Order int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    CREATE INDEX IX_Tmp_DepTable_Sort_Order ON Tmp_DepTable (Sort_Order);

    ---------------------------------------------------
    -- For steps that are waiting,
    -- get unevaluated dependencies that target steps
    -- that are finished (skipped or completed)
    ---------------------------------------------------

    INSERT INTO Tmp_DepTable (
        job,
        Dependent_Step,
        Target_Step,
        Target_State,
        Target_Completion_Code,
        condition_test,
        test_value,
        enable_only
    )
    SELECT JS.job,
           JSD.step AS Dependent_Step,
           JS.step AS Target_Step,
           JS.state AS Target_State,
           JS.completion_code AS Target_Completion_Code,
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
    WHERE JSD.evaluated = 0 AND
          JS.state IN (3, 5) AND
          JS_B.state = 1;

    If Not FOUND Then
        -- Nothing found, nothing to process

        If _infoOnly Then
            RAISE INFO 'Did not find any job steps to process';
        End If;

        DROP TABLE Tmp_DepTable;
        RETURN;
    End If;

    If _maxJobsToProcess > 0 Then
        -- Limit the number of jobs to evaluate
        DELETE FROM Tmp_DepTable
        WHERE NOT Job IN ( SELECT Job
                           FROM Tmp_DepTable
                           ORDER BY Job
                           LIMIT _maxJobsToProcess );

    End If;

    If _infoOnly Then

        -- Preview the steps to process

        RAISE INFO '';

        _formatSpecifier := '%-9s %-14s %-11s %-12s %-22s %-15s %-10s %-11s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Dependent_Step',
                            'Target_Step',
                            'Target_State',
                            'Target_Completion_Code',
                            'Condition_Test',
                            'Test_Value',
                            'Enable_Only',
                            'Sort_Order'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '--------------',
                                     '-----------',
                                     '------------',
                                     '----------------------',
                                     '---------------',
                                     '----------',
                                     '-----------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job,
                   Dependent_Step,
                   Target_Step,
                   Target_State,
                   Target_Completion_Code,
                   Condition_Test,
                   Test_Value,
                   Enable_Only,
                   Sort_Order
            FROM Tmp_DepTable
            ORDER BY Sort_Order
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Dependent_Step,
                                _previewData.Target_Step,
                                _previewData.Target_State,
                                _previewData.Target_Completion_Code,
                                _previewData.Condition_Test,
                                _previewData.Test_Value,
                                _previewData.Enable_Only,
                                _previewData.Sort_Order
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    ---------------------------------------------------
    -- Loop though dependencies and evaluate them
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _rowCountToProcess
    FROM Tmp_DepTable;

    If _rowCountToProcess = 0 Then
        DROP TABLE Tmp_DepTable;
        RETURN;
    End If;

    _sortOrder := -1;

    WHILE true
    LOOP
        ---------------------------------------------------
        -- Get next step dependency
        ---------------------------------------------------

        SELECT Sort_Order,
               Job,
               Dependent_Step,
               Target_Step,
               Target_State,
               Target_Completion_Code,
               Condition_Test,
               Test_Value,
               Enable_Only
        INTO _sortOrder, _job, _dependentStep, _targetStep, _targetState, _targetCompletionCode, _condition_Test, _testValue, _enableOnly
        FROM Tmp_DepTable
        WHERE Sort_Order > _sortOrder
        ORDER BY Sort_Order
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        ---------------------------------------------------
        -- Evaluate dependency condition (if one is defined)
        ---------------------------------------------------

        _triggered := false;

        If _infoOnly Then
            RAISE INFO '';
        End If;

        ---------------------------------------------------
        -- Skip if signature of dependent step matches the test value
        -- (usually used with value of '0', which happens when there are no parameters)
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
                _message := format('Error getting dependent step filter signature: step %s for job %s not found in sw.t_job_steps', _dependentStep, _job);
                _returnCode := 'U5431';

                DROP TABLE Tmp_DepTable;
                RETURN;
            End If;

            If _actualValue = 0 Then
                _triggered := true;
            End If;
        End If;

        ---------------------------------------------------
        -- Skip if state of target step is skipped
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
                _message := format('Error getting target step state: step %s for job %s not found in sw.t_job_steps', _targetStep, _job);
                _returnCode := 'U5432';

                DROP TABLE Tmp_DepTable;
                RETURN;
            End If;

            If _actualValue = 3 Then
                _triggered := true;
            End If;
        End If;

        ---------------------------------------------------
        -- Skip if completion message of target step contains test value
        --
        If _condition_Test = 'Completion_Message_Contains' Then
            -- Get completion message for target step
            --
            SELECT completion_message
            INTO _targetCompletionMessage
            FROM sw.t_job_steps
            WHERE job = _job AND
                  step = _targetStep;

            If FOUND And _targetCompletionMessage Like ('%' || _testValue || '%')::citext Then
                _triggered := true;
            End If;
        End If;

        If _infoOnly And Coalesce(_condition_Test, '') <> '' Then
            RAISE INFO 'Dependent Step %, Target Step %, Condition Test %; Triggered = %',
                        _dependentStep, _targetStep, _condition_Test, CASE WHEN _triggered THEN 1 ELSE 0 END;
        End If;

        ---------------------------------------------------
        -- Copy output folder from target step
        -- to be input folder for dependent step,
        -- unless dependency is 'Enable_Only'
        ---------------------------------------------------

        If _enableOnly = 0 Then

            SELECT output_folder_name
            INTO _outputFolderName
            FROM sw.t_job_steps
            WHERE job = _job AND
                  step = _targetStep;

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

        If _infoOnly Then
            RAISE INFO 'Update job %, step % with target step % to have evaluated=1 and triggered=% in table sw.t_job_step_dependencies',
                          _job, _dependentStep, _targetStep, CASE WHEN _triggered THEN 1 ELSE 0 END;
        Else
            UPDATE sw.t_job_step_dependencies
            SET Evaluated = 1,
                Triggered = CASE WHEN _triggered THEN 1 ELSE 0 END
            WHERE Job = _job AND
                  Step = _dependentStep AND
                  Target_Step = _targetStep;
        End If;

        _rowsProcessed := _rowsProcessed + 1;

        If extract(epoch FROM (clock_timestamp() - _lastLogTime)) >= _loopingUpdateInterval Then

            _statusMessage := format('... Evaluating step dependencies: %s / %s', _rowsProcessed, _rowCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Evaluate_Step_Dependencies', 'sw');

            _lastLogTime := clock_timestamp();
        End If;

    END LOOP;

    DROP TABLE Tmp_DepTable;

END
$$;


ALTER PROCEDURE sw.evaluate_step_dependencies(IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE evaluate_step_dependencies(IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.evaluate_step_dependencies(IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'EvaluateStepDependencies';

