--
-- Name: get_task_script_dot_format_table(text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_script_dot_format_table(_script text) RETURNS TABLE(script_line text, seq integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns Dot graphic command list (as table) for given script
**
**  Auth:   mem
**  Date:   06/25/2022 mem - Ported to PostgreSQL by converting V_Script_Dot_Format to a function
**
****************************************************/
DECLARE
    _scriptStep record;
BEGIN
    CREATE TEMP TABLE Tmp_ScriptSteps (
        step_number int,
        step_tool text
    );

    -- Populate a table with the steps for each script
    -- This query processes XML to extract step number and step tool, e.g.
    --   <JobScript Name="DatasetCapture">
    --     <Step Number="1" Tool="DatasetCapture"/>
    --     <Step Number="2" Tool="DatasetIntegrity">
    --       <Depends_On Step_Number="1"/>
    --     </Step>
    --     <Step Number="3" Tool="DatasetInfo">
    --       <Depends_On Step_Number="2"/>
    --     </Step>
    --     <Step Number="4" Tool="DatasetQuality">
    --       <Depends_On Step_Number="3"/>
    --     </Step>
    --   </JobScript>

    INSERT INTO Tmp_ScriptSteps(step_number, step_tool)
    SELECT XmlTableA.step_number, XmlTableA.step_tool   --, t1::text AS ScriptXML
    FROM cap.t_scripts Src,
        LATERAL unnest((
            SELECT
                xpath('//JobScript', contents)
        )) t1,
        XMLTABLE('//JobScript/Step'
                          PASSING t1
                          COLUMNS step_number int PATH '@Number',
                                  step_tool text PATH '@Tool',
                                  parent_steps XML PATH 'Depends_On') As XmlTableA
    WHERE Src.script = _script
    ORDER BY XmlTableA.step_number;

    -- Return the script lines that define the script steps
    RETURN QUERY
    SELECT format('%s [label="%s %s"] [shape=box, color=black];', step_number, step_number, step_tool) as script_line,
           0 as seq
    FROM Tmp_ScriptSteps
    ORDER BY step_number;

    -- Extract the job step dependencies
    -- Cannot directly use XMLTABLE() since some steps have multiple dependencies
    -- Note that this query uses XPATH to filter on script name
    --
    FOR _scriptStep IN
        SELECT XmlTableA.step_number, XmlTableA.step_tool, XmlTableA.parent_steps::text
        FROM cap.t_scripts Src,
            LATERAL unnest((
                SELECT
                    xpath('//JobScript', Src.contents)
            )) t1,
            XMLTABLE('//JobScript/Step'
                              PASSING t1
                              COLUMNS step_number int PATH '@Number',
                                      step_tool text PATH '@Tool',
                                      parent_steps XML PATH 'Depends_On') As XmlTableA
        WHERE Src.script = _script
    LOOP
        If Not _scriptStep.parent_steps Is Null Then
            -- _scriptStep.parent_steps will have one or more parent steps, e.g.
            -- <Depends_On Step_Number="2"/><Depends_On Step_Number="3"/>

            -- Append rows to the output table
            -- Use XPath to extract the step numbers

            RETURN QUERY
            SELECT format('%s -> %s;', XmlTableA.parent_step, _scriptStep.step_number) as script_line,
                   1 as seq
            FROM ( SELECT ('<root>' || _scriptStep.parent_steps || '</root>')::xml as rooted_xml
                 ) Src,
                 XMLTABLE('//root/Depends_On'
                          PASSING Src.rooted_xml
                          COLUMNS parent_step int PATH '@Step_Number') As XmlTableA
            ORDER BY XmlTableA.parent_step, _scriptStep.step_number;
        End If;

    END LOOP;

    Drop Table Tmp_ScriptSteps;
END
$$;


ALTER FUNCTION cap.get_task_script_dot_format_table(_script text) OWNER TO d3l243;

