--
-- Name: get_task_script_dot_format_table(text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_task_script_dot_format_table(_script text) RETURNS TABLE(script_line text, seq integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return Dot graphic command list (as table) for given script
**
**  Example usage:
**
**    Single script:
**      SELECT * FROM sw.get_task_script_dot_format_table('msgfplus')
**      SELECT * FROM sw.get_task_script_dot_format_table('XTandem')
**
**    All pipeline scripts:
**      SELECT Script, ScriptLines.*
**      FROM sw.t_scripts
**           JOIN LATERAL (
**               SELECT * FROM sw.get_task_script_dot_format_table(script)
**           ) As ScriptLines On true
**      ORDER BY script, seq, script_line;
**
**
**    View v_script_dot_format returns identical information as this function
**
**      SELECT *
**      FROM sw.v_script_dot_format
**      WHERE script = 'msgfplus'
**      ORDER BY seq, line;
**
**      SELECT *
**      FROM sw.v_script_dot_format
**      ORDER BY script, seq, line;
**
**
**  Auth:   mem
**  Date:   06/25/2022 mem - Ported to PostgreSQL by converting V_Script_Dot_Format to a function
**          08/17/2022 mem - Use case-insensitive comparison for script name
**          12/18/2022 mem - Customized for the pipeline jobs schema
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _scriptStep record;
BEGIN
    CREATE TEMP TABLE Tmp_ScriptSteps (
        step int,
        tool text,
        special_instructions text,
        shared_result_version int
    );

    -- Populate a table with the steps for each script
    -- This query processes XML to extract step number and step tool, e.g.
    --   <JobScript Name="Sequest">
    --     <Step Number="1" Tool="DTA_Gen" />
    --     <Step Number="2" Tool="MSMSSpectraPreprocessor">
    --       <Depends_On Step_Number="1" Test="No_Parameters" />
    --     </Step>
    --     <Step Number="3" Tool="Sequest">
    --       <Depends_On Step_Number="2" />
    --     </Step>
    --     <Step Number="4" Tool="DataExtractor">
    --       <Depends_On Step_Number="3" />
    --     </Step>
    --     <Step Number="5" Tool="MSGF">
    --       <Depends_On Step_Number="4" />
    --     </Step>
    --     <Step Number="6" Tool="Results_Transfer">
    --       <Depends_On Step_Number="5" />
    --     </Step>
    --   </JobScript>

    INSERT INTO Tmp_ScriptSteps(step, tool, special_instructions, shared_result_version)
    SELECT ScriptQ.step, ScriptQ.tool, ScriptQ.special_instructions, StepTools.shared_result_version   --, t1::text AS ScriptXML
    FROM ( SELECT XmlTableA.*
           FROM sw.t_scripts Src,
               LATERAL unnest((
                   SELECT
                       xpath('//JobScript', contents)
               )) t1,
               XMLTABLE('//JobScript/Step'
                                 PASSING t1
                                 COLUMNS step int PATH '@Number',
                                         tool text PATH '@Tool',
                                         special_instructions citext PATH '@Special',
                                         parent_steps XML PATH 'Depends_On') As XmlTableA
            WHERE Src.script = _script::citext
          ) ScriptQ INNER JOIN
          sw.t_step_tools StepTools ON ScriptQ.tool = StepTools.step_tool
    ORDER BY ScriptQ.step;

    -- Return the script lines that define the script steps
    RETURN QUERY
    SELECT format('%s [label="%s %s%s"] [shape=%s, color=black%s];',
                  step, step, tool,
                  CASE WHEN special_instructions IS NULL                 THEN ''          ELSE format('(%s)', special_instructions) END,
                  CASE WHEN COALESCE(special_instructions, '') = 'Clone' THEN 'trapezium' ELSE 'box' END,
                  CASE WHEN COALESCE(shared_result_version, 0) = 0       THEN ''          ELSE ', style=filled, fillcolor=lightblue, peripheries=2' END)
             As script_line,
           0 As seq
    FROM Tmp_ScriptSteps
    ORDER BY step;

    -- Extract the job step dependencies
    -- Cannot directly use XMLTABLE() since some steps have multiple dependencies
    -- Note that this query uses XPATH to filter on script name

    FOR _scriptStep IN
        SELECT XmlTableA.step, XmlTableA.tool, XmlTableA.parent_steps::text
        FROM sw.t_scripts Src,
            LATERAL unnest((
                SELECT
                    xpath('//JobScript', Src.contents)
            )) t1,
            XMLTABLE('//JobScript/Step'
                              PASSING t1
                              COLUMNS step int PATH '@Number',
                                      tool text PATH '@Tool',
                                      parent_steps XML PATH 'Depends_On') As XmlTableA
        WHERE Src.script = _script::citext
    LOOP
        If Not _scriptStep.parent_steps Is Null Then
            -- _scriptStep.parent_steps will have one or more parent steps, e.g.
            -- <Depends_On Step_Number="2"/><Depends_On Step_Number="3"/>

            -- Append rows to the output table
            -- Use XPath to extract the step numbers

            RETURN QUERY
            SELECT format('%s -> %s%s%s;',
                          XmlTableA.parent_step,
                          _scriptStep.step,
                          CASE WHEN XmlTableA.condition_test IS NULL       THEN ''                ELSE format(' [label="Skip if:%s"]', XmlTableA.condition_test) END,
                          CASE WHEN Coalesce(XmlTableA.enable_only, 0) > 0 THEN ' [style=dotted]' ELSE '' END)
                     As script_line,
                   1 As seq
            FROM ( SELECT ('<root>' || _scriptStep.parent_steps || '</root>')::xml as rooted_xml
                 ) Src,
                 XMLTABLE('//root/Depends_On'
                          PASSING Src.rooted_xml
                          COLUMNS parent_step int PATH '@Step_Number',
                                  condition_test citext PATH '@Test',
                                  test_value     citext PATH '@Value',
                                  enable_only    int PATH '@Enable_Only'

                          ) As XmlTableA
            ORDER BY XmlTableA.parent_step, _scriptStep.step;
        End If;

    END LOOP;

    DROP TABLE Tmp_ScriptSteps;
END
$$;


ALTER FUNCTION sw.get_task_script_dot_format_table(_script text) OWNER TO d3l243;

