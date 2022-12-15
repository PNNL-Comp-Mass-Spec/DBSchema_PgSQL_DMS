--
-- Name: v_pipeline_script_detail_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_script_detail_report AS
 SELECT t_scripts.script_id AS id,
    t_scripts.script,
    t_scripts.description,
    t_scripts.enabled,
    t_scripts.results_tag,
        CASE
            WHEN (t_scripts.backfill_to_dms = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS backfill_to_dms,
    (('<pre>'::text || replace(replace(TRIM(BOTH FROM replace((t_scripts.contents)::text, '<'::text, ((chr(13) || chr(10)) || '<'::text))), '<'::text, '&lt;'::text), '>'::text, '&gt;'::text)) || '</pre>'::text) AS contents,
    (('<pre>'::text || replace(replace(TRIM(BOTH FROM replace((t_scripts.parameters)::text, '<'::text, ((chr(13) || chr(10)) || '<'::text))), '<'::text, '&lt;'::text), '>'::text, '&gt;'::text)) || '</pre>'::text) AS parameters,
    (('<pre>'::text || replace(replace(TRIM(BOTH FROM replace((t_scripts.fields)::text, '<'::text, ((chr(13) || chr(10)) || '<'::text))), '<'::text, '&lt;'::text), '>'::text, '&gt;'::text)) || '</pre>'::text) AS fields_for_wizard
   FROM sw.t_scripts;


ALTER TABLE sw.v_pipeline_script_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_script_detail_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_script_detail_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_script_detail_report TO writeaccess;

