--
-- Name: finish_task_creation(integer, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.finish_task_creation(IN _job integer, INOUT _message text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Perform a mixed bag of operations on the capture task jobs
**      in the temporary tables to finalize them before
**      copying to the main database tables
**
**      Uses the following temporary tables created by the calling procedure
**          Tmp_Jobs
**          Tmp_Job_Steps
**          Tmp_Job_Step_Dependencies
**
**  Auth:   grk
**  Date:   01/31/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/06/2009 grk - Added code for: Special="Job_Results"
**          07/31/2009 mem - Now filtering by capture task job in the subquery that looks for job steps with flag Special="Job_Results" (necessary when Tmp_Job_Steps contains more than one capture task job)
**          04/08/2011 mem - Now skipping the 'ImsDeMultiplex' step for datasets that end in '_inverse'
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          10/11/2022 mem - Ported to PostgreSQL
**          02/02/2023 mem - Update table aliases
**
*****************************************************/
DECLARE
    _stepCountWithDependencies int;
    _stepCountNoDependencies int;
BEGIN
    _message := '';
    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Update step dependency count
    ---------------------------------------------------
    --
    UPDATE Tmp_Job_Steps
    SET Dependencies = T.dependencies
    FROM ( SELECT Step,
                  COUNT(*) AS dependencies
           FROM Tmp_Job_Step_Dependencies
           WHERE Job = _job
           GROUP BY Step
        ) AS T
    WHERE Tmp_Job_Steps.Job = _job AND
          T.Step = Tmp_Job_Steps.Step;
    --
    GET DIAGNOSTICS _stepCountWithDependencies = ROW_COUNT;

    ---------------------------------------------------
    -- Initialize input directory of dataset
    -- for steps that have no dependencies
    ---------------------------------------------------
    --
    UPDATE Tmp_Job_Steps
    SET Input_Directory_Name = ''
    WHERE Dependencies = 0 AND
          Job = _job;
    --
    GET DIAGNOSTICS _stepCountNoDependencies = ROW_COUNT;

    If _debugMode Then
        RAISE INFO ' ';
        RAISE INFO 'Job % has % % with a dependency and % % without a dependency',
                    _job,
                    _stepCountWithDependencies, public.check_plural(_stepCountWithDependencies, 'step', 'steps'),
                    _stepCountNoDependencies,   public.check_plural(_stepCountNoDependencies,   'step', 'steps');
    End If;

    ---------------------------------------------------
    -- Set results directory name for capture task job to be that of
    -- the output directory for any step where
    -- Special_Instructions is 'Job_Results'
    --
    -- This will only affect capture task jobs that have a step with
    -- the Special_Instructions = 'Job_Results' attribute
    ---------------------------------------------------
    --
    UPDATE Tmp_Jobs
    SET Results_Directory_Name = LookupQ.Output_Directory_Name
    FROM ( SELECT Job, Output_Directory_Name
           FROM Tmp_Job_Steps
           WHERE Job = _job AND
                 Special_Instructions = 'Job_Results'
           ORDER BY Step
           LIMIT 1
         ) LookupQ
    WHERE Tmp_Jobs.Job = LookupQ.Job;

    ---------------------------------------------------
    -- Skip the demultiplex step for datasets that end in _inverse
    -- These datasets have already been demultiplexed
    ---------------------------------------------------
    --
    UPDATE Tmp_Job_Steps TS
    SET State = 3
    FROM Tmp_Jobs T
    WHERE TS.Job = T.Job AND
          T.Dataset SIMILAR TO '%[_]inverse' AND
          TS.Tool = 'ImsDeMultiplex';

    If FOUND Then
        RAISE INFO 'Skipped the ImsDeMultiplex step for job % because the dataset name ends with "_inverse"', _job;
    End If;

    ---------------------------------------------------
    -- Set capture task job state to 1 ("New")
    ---------------------------------------------------
    --
    UPDATE Tmp_Jobs
    SET State = 1
    WHERE Job = _job;

END
$$;


ALTER PROCEDURE cap.finish_task_creation(IN _job integer, INOUT _message text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE finish_task_creation(IN _job integer, INOUT _message text, IN _debugmode boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.finish_task_creation(IN _job integer, INOUT _message text, IN _debugmode boolean) IS 'FinishJobCreation';

