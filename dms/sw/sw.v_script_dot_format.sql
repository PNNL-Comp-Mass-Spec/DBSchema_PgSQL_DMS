--
-- Name: v_script_dot_format; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_script_dot_format AS
 SELECT scriptq.script,
    (((((((((((scriptq.step || ' [label="'::text) || (scriptq.step)::text) || ' '::text) || (scriptq.step_tool)::text) ||
        CASE
            WHEN (scriptq.special_instructions IS NULL) THEN ''::text
            ELSE ((' ('::text || (scriptq.special_instructions)::text) || ')'::text)
        END) || '"'::text) || '] '::text) ||
        CASE
            WHEN (COALESCE(scriptq.special_instructions, ''::public.citext) OPERATOR(public.=) 'Clone'::public.citext) THEN '[shape=trapezium, '::text
            ELSE '[shape=box, '::text
        END) || 'color=black'::text) ||
        CASE
            WHEN (COALESCE((steptools.shared_result_version)::integer, 0) = 0) THEN ''::text
            ELSE ', style=filled, fillcolor=lightblue, peripheries=2'::text
        END) || '];'::text) AS line,
    0 AS seq
   FROM (( SELECT xmlq.script,
            xmlq.step,
            xmlq.step_tool,
            xmlq.special_instructions
           FROM (( SELECT t_scripts.script,
                    t_scripts.contents AS scriptxml
                   FROM sw.t_scripts) lookupq
             JOIN LATERAL ( SELECT lookupq.script,
                    "xmltable".step,
                    "xmltable".step_tool,
                    "xmltable".special_instructions
                   FROM ( SELECT lookupq.scriptxml) src,
                    LATERAL XMLTABLE(('//JobScript/Step'::text) PASSING (src.scriptxml) COLUMNS step integer PATH ('@Number'::text), step_tool public.citext PATH ('@Tool'::text), special_instructions public.citext PATH ('@Special'::text))) xmlq ON ((lookupq.script OPERATOR(public.=) xmlq.script)))) scriptq
     JOIN sw.t_step_tools steptools ON ((scriptq.step_tool OPERATOR(public.=) steptools.step_tool)))
UNION
 SELECT enableonlyq.script,
    ((((((enableonlyq.target_step)::text || ' -> '::text) || (enableonlyq.step)::text) ||
        CASE
            WHEN (enableonlyq.condition_test IS NULL) THEN ''::text
            ELSE ((' [label="Skip if:'::text || (enableonlyq.condition_test)::text) || '"]'::text)
        END) ||
        CASE
            WHEN (COALESCE(enableonlyq.enable_only, 0) > 0) THEN ' [style=dotted]'::text
            ELSE ''::text
        END) || ';'::text) AS line,
    1 AS seq
   FROM ( SELECT xmlq.script,
            xmlq.step,
            xmlq.target_step,
            xmlq.condition_test,
            xmlq.test_value,
            xmlq.enable_only
           FROM (( SELECT t_scripts.script,
                    t_scripts.contents AS scriptxml
                   FROM sw.t_scripts) lookupq
             JOIN LATERAL ( SELECT lookupq.script,
                    "xmltable".step,
                    "xmltable".target_step,
                    "xmltable".condition_test,
                    "xmltable".test_value,
                    "xmltable".enable_only
                   FROM ( SELECT lookupq.scriptxml) src,
                    LATERAL XMLTABLE(('//JobScript/Step/Depends_On'::text) PASSING (src.scriptxml) COLUMNS step integer PATH ('../@Number'::text), target_step integer PATH ('@Step_Number'::text), condition_test public.citext PATH ('@Test'::text), test_value public.citext PATH ('@Value'::text), enable_only integer PATH ('@Enable_Only'::text))) xmlq ON ((lookupq.script OPERATOR(public.=) xmlq.script)))) enableonlyq;


ALTER TABLE sw.v_script_dot_format OWNER TO d3l243;

--
-- Name: TABLE v_script_dot_format; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_script_dot_format TO readaccess;
GRANT SELECT ON TABLE sw.v_script_dot_format TO writeaccess;

