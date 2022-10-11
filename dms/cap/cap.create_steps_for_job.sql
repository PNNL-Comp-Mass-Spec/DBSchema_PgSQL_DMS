--
-- Name: create_steps_for_job(integer, xml, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make entries in temporary tables for the the given capture task job according to definition of scriptXML
**      Uses temp tables:
**        Tmp_Job_Steps
**        Tmp_Job_Step_Dependencies
**
**  Auth:   grk
**  Date:   09/05/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/25/2011 mem - Removed _priority parameter and removed priority column from t_task_steps
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          10/11/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stepCount int;
    _stepDependencyCount int;
BEGIN
    _message := '';
    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Make set of capture task job steps for job based on _scriptXML
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Job_Steps (
        Job,
        Step,
        Step_Tool,
--        CPU_Load,
        Dependencies,
        State,
        Output_Directory_Name,
        Special_Instructions,
        Holdoff_Interval_Minutes,
        Retry_Count
    )
    SELECT _job AS Job,
           XmlQ.step,
           XmlQ.step_tool,
    --     CPU_Load,
           0 AS Dependencies,
           1 AS State,
           _resultsDirectoryName,
           XmlQ.special_instructions,
           T.holdoff_interval_minutes,
           T.number_of_retries
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _scriptXML As ScriptXML ) Src,
             XMLTABLE('//JobScript/Step'
                      PASSING Src.ScriptXML
                      COLUMNS step int PATH '@Number',
                              step_tool citext PATH '@Tool',
                              special_instructions citext PATH '@Special')
         ) XmlQ INNER JOIN
         cap.t_step_tools T ON XmlQ.step_tool = T.step_tool;
    --
    GET DIAGNOSTICS _stepCount = ROW_COUNT;

    ---------------------------------------------------
    -- Make set of step dependencies based on scriptXML
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Job_Step_Dependencies
    (
        Step,
        Target_Step,
        Condition_Test,
        Test_Value,
        Enable_Only,
        Job
    )
    SELECT
        step,
        target_step,
        condition_test,
        test_value,
        Coalesce(public.try_cast(enable_only, 0), 0) AS Enable_Only,
        _job AS Job
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _scriptXML As ScriptXML ) Src,
             XMLTABLE('//JobScript/Step/Depends_On'
                      PASSING Src.ScriptXML
                      COLUMNS step int PATH '../@Number',
                              target_step int PATH '@Step_Number',
                              condition_test citext PATH '@Test',
                              test_value citext PATH '@Value',
                              enable_only citext PATH '@Enable_Only')
         ) XmlQ;
    --
    GET DIAGNOSTICS _stepDependencyCount = ROW_COUNT;

    If _debugMode Then
        RAISE INFO 'For job %, added % % to Tmp_Job_Steps and added % % to Tmp_Job_Step_Dependencies',
                    _job,
                    _stepCount,           public.check_plural(_stepCount, 'step', 'steps'),
                    _stepDependencyCount, public.check_plural(_stepDependencyCount, 'dependency', 'dependencies');
    End If;
END
$$;


ALTER PROCEDURE cap.create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, IN _debugmode boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, IN _debugmode boolean) IS 'CreateStepsForJob';
