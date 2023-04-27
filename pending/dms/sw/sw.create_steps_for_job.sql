--
CREATE OR REPLACE PROCEDURE sw.create_steps_for_job
(
    _job int,
    _scriptXML xml,
    _resultsDirectoryName text,
    INOUT _message text,
    INOUT _returnCode text,
    _debugMode boolean = false
)
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
**  Auth:   grk
**  Date:   08/23/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          12/05/2008 mem - Changed the formatting of the auto-generated results folder name
**          01/14/2009 mem - Increased maximum Value length in Tmp_Job_Parameters to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          01/28/2009 grk - modified for parallelization (http://prismtrac.pnl.gov/trac/ticket/718)
**          01/30/2009 grk - modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**          02/05/2009 grk - modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed _priority parameter and removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          04/16/2012 grk - Added error checking for missing step tools
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          12/15/2023 mem - Ported to PostgreSQL
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
    --
    SELECT string_agg(XmlQ.Tool, ', ')
    INTO _missingTools
    FROM ( SELECT xmltable.tool
           FROM ( SELECT _scriptXML As ScriptXML ) Src,
                XMLTABLE('//JobScript/Step'
                         PASSING Src.ScriptXML
                         COLUMNS step int PATH '@Number',
                                 tool citext PATH '@Tool',
                                 special_instructions citext PATH '@Special')
         ) XmlQ
    WHERE NOT XmlQ.tool IN ( SELECT StepTools.step_tool FROM sw.t_step_tools StepTools );

    If _missingTools <> '' Then
        _message := 'Step tool(s) ' || _missingTools || ' do not exist in t_step_tools';
        _returnCode := 'U5301';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make set of job steps for job based on _scriptXML
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Job_Steps (
        job,
        step,
        tool,
        cpu_load,
        memory_usage_mb,
        shared_result_version,
        filter_version,
        dependencies,
        state,
        output_directory_name,
        special_instructions
    )
    SELECT
        _job AS job,
        XmlQ.step,
        XmlQ.tool,
        T.cpu_load,
        T.memory_usage_mb,
        T.shared_result_version,
        T.filter_version,
        0 AS dependencies,
        1 AS state,
        _resultsDirectoryName,
        XmlQ.special_instructions
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _scriptXML As ScriptXML ) Src,
             XMLTABLE('//JobScript/Step'
                      PASSING Src.ScriptXML
                      COLUMNS step int PATH '@Number',
                              tool citext PATH '@Tool',
                              special_instructions citext PATH '@Special')
         ) XmlQ INNER JOIN
         sw.t_step_tools ST ON XmlQ.tool = ST.step_tool;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

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


END
$$;

COMMENT ON PROCEDURE sw.create_steps_for_job IS 'CreateStepsForJob';
