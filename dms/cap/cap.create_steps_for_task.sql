--
-- Name: create_steps_for_task(integer, xml, text, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.create_steps_for_task(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, INOUT _returncode text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make entries in temporary tables for the the given capture task job according to definition of _scriptXML
**      Uses temp tables:
**        Tmp_Job_Steps
**        Tmp_Job_Step_Dependencies
**
**  Arguments:
**    _job                      Capture task job number
**    _scriptXML                Capture task script XML
**    _resultsdirectoryname     Results directory name
**    _message                  Status message
**    _returnCode               Return code
**    _debugmode                When true, show additional messages
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/25/2011 mem - Removed _priority parameter and removed priority column from t_task_steps
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          10/11/2022 mem - Ported to PostgreSQL
**          11/30/2022 mem - Add parameter _returnCode and add check for missing step tools
**          03/07/2023 mem - Rename column in temporary table
**          03/08/2023 mem - Switch back to t_step_tools.step_tool
**          04/02/2023 mem - Rename procedure and functions
**          05/23/2023 mem - Use format() for string concatenation
**          06/07/2023 mem - Add Order By to string_agg()
**          06/19/2023 mem - Fix table alias typo
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _missingTools text;
    _stepCount int;
    _stepDependencyCount int;
BEGIN
    _message := '';
    _returnCode := '';
    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Make sure that the tools in the script exist
    ---------------------------------------------------

    SELECT string_agg(XmlQ.tool, ', ' ORDER BY XmlQ.tool)
    INTO _missingTools
    FROM ( SELECT Trim(xmltable.tool)::citext AS Tool
           FROM ( SELECT _scriptXML AS ScriptXML ) Src,
                XMLTABLE('//JobScript/Step'
                         PASSING Src.ScriptXML
                         COLUMNS step                 int  PATH '@Number',
                                 tool                 text PATH '@Tool',
                                 special_instructions text PATH '@Special')
         ) XmlQ
    WHERE NOT XmlQ.tool IN (SELECT ST.step_tool FROM cap.t_step_tools ST);

    If _missingTools <> '' Then
        _message := format('Step tool(s) %s do not exist in cap.t_step_tools', _missingTools);
        _returnCode := 'U5301';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make set of capture task job steps for job based on _scriptXML
    ---------------------------------------------------

    INSERT INTO Tmp_Job_Steps (
        Job,
        Step,
        Tool,
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
           Trim(XmlQ.tool) AS tool,
    --     CPU_Load,
           0 AS Dependencies,
           1 AS State,
           _resultsDirectoryName,
           Trim(XmlQ.special_instructions) AS special_instructions,
           ST.holdoff_interval_minutes,
           ST.number_of_retries
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _scriptXML AS ScriptXML ) Src,
             XMLTABLE('//JobScript/Step'
                      PASSING Src.ScriptXML
                      COLUMNS step                 int  PATH '@Number',
                              tool                 text PATH '@Tool',
                              special_instructions text PATH '@Special')
         ) XmlQ
         INNER JOIN cap.t_step_tools ST
           ON XmlQ.tool = ST.step_tool;
    --
    GET DIAGNOSTICS _stepCount = ROW_COUNT;

    ---------------------------------------------------
    -- Make set of step dependencies based on scriptXML
    ---------------------------------------------------

    INSERT INTO Tmp_Job_Step_Dependencies (
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
        Trim(condition_test) AS condition_test,
        Trim(test_value) AS test_value,
        Coalesce(public.try_cast(enable_only, 0), 0) AS Enable_Only,
        _job AS Job
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _scriptXML AS ScriptXML ) Src,
             XMLTABLE('//JobScript/Step/Depends_On'
                      PASSING Src.ScriptXML
                      COLUMNS step           int  PATH '../@Number',
                              target_step    int  PATH '@Step_Number',
                              condition_test text PATH '@Test',
                              test_value     text PATH '@Value',
                              enable_only    text PATH '@Enable_Only')
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


ALTER PROCEDURE cap.create_steps_for_task(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE create_steps_for_task(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, INOUT _returncode text, IN _debugmode boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.create_steps_for_task(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) IS 'CreateStepsForTask or CreateStepsForJob';

