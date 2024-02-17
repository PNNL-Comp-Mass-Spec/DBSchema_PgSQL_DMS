--
-- Name: create_steps_for_job(integer, xml, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make entries in temporary tables for the the given analysis job according to definition of _scriptXML
**
**      Uses temp tables created by sw.make_local_job_in_broker
**        Tmp_Job_Steps
**        Tmp_Job_Step_Dependencies
**
**  Arguments:
**    _job                      Job number
**    _scriptXML                XML loaded from table sw.t_scripts
**    _resultsDirectoryName     Results directory name
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   08/23/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          12/05/2008 mem - Changed the formatting of the auto-generated results folder name
**          01/14/2009 mem - Increased maximum Value length in Tmp_Job_Parameters to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          01/28/2009 grk - Modified for parallelization (http://prismtrac.pnl.gov/trac/ticket/718)
**          01/30/2009 grk - Modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**          02/05/2009 grk - Modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed _priority parameter and removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          04/16/2012 grk - Added error checking for missing step tools
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          07/28/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _missingTools text := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Make sure that the tools in the script exist
    ---------------------------------------------------

    SELECT string_agg(XmlQ.Tool, ', ' ORDER BY XmlQ.Tool)
    INTO _missingTools
    FROM ( SELECT xmltable.tool
           FROM ( SELECT _scriptXML AS ScriptXML ) Src,
                XMLTABLE('//JobScript/Step'
                         PASSING Src.ScriptXML
                         COLUMNS step int PATH '@Number',
                                 tool citext PATH '@Tool',
                                 special_instructions citext PATH '@Special')
         ) XmlQ
    WHERE NOT XmlQ.tool IN ( SELECT StepTools.step_tool FROM sw.t_step_tools StepTools );

    If _missingTools <> '' Then
        _message := format('Step tool(s) %s do not exist in sw.t_step_tools', _missingTools);
        _returnCode := 'U5301';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make set of job steps for job based on _scriptXML
    ---------------------------------------------------

    INSERT INTO Tmp_Job_Steps (
        Job,
        Step,
        Tool,
        Cpu_Load,
        Memory_Usage_MB,
        Shared_Result_Version,
        Filter_Version,
        Dependencies,
        State,
        Output_Directory_Name,
        Special_Instructions
    )
    SELECT
        _job AS job,
        XmlQ.step,
        XmlQ.tool,
        ST.cpu_load,
        ST.memory_usage_mb,
        ST.shared_result_version,
        ST.filter_version,
        0 AS dependencies,
        1 AS state,
        _resultsDirectoryName,
        XmlQ.special_instructions
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _scriptXML AS ScriptXML ) Src,
             XMLTABLE('//JobScript/Step'
                      PASSING Src.ScriptXML
                      COLUMNS step int PATH '@Number',
                              tool citext PATH '@Tool',
                              special_instructions citext PATH '@Special')
         ) XmlQ INNER JOIN
         sw.t_step_tools ST ON XmlQ.tool = ST.step_tool;

    ---------------------------------------------------
    -- Make set of step dependencies based on scriptXML
    ---------------------------------------------------

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
        FROM ( SELECT _scriptXML AS ScriptXML ) Src,
             XMLTABLE('//JobScript/Step/Depends_On'
                      PASSING Src.ScriptXML
                      COLUMNS step int PATH '../@Number',
                              target_step int PATH '@Step_Number',
                              condition_test citext PATH '@Test',
                              test_value citext PATH '@Value',
                              enable_only citext PATH '@Enable_Only')
         ) XmlQ;

END
$$;


ALTER PROCEDURE sw.create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.create_steps_for_job(IN _job integer, IN _scriptxml xml, IN _resultsdirectoryname text, INOUT _message text, INOUT _returncode text) IS 'CreateStepsForJob';

