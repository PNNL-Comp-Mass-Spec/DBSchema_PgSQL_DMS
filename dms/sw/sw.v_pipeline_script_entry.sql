--
-- Name: v_pipeline_script_entry; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_script_entry AS
 SELECT t_scripts.script_id AS id,
    t_scripts.script,
    t_scripts.description,
    t_scripts.enabled,
    t_scripts.results_tag,
        CASE
            WHEN (t_scripts.backfill_to_dms = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS backfill_to_dms,
    t_scripts.contents,
    t_scripts.parameters,
    t_scripts.fields
   FROM sw.t_scripts;


ALTER TABLE sw.v_pipeline_script_entry OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_script_entry; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_script_entry TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_script_entry TO writeaccess;

