--
-- Name: v_pipeline_script_entry; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_script_entry AS
 SELECT script_id AS id,
    script,
    description,
    enabled,
    results_tag,
        CASE
            WHEN (backfill_to_dms = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS backfill_to_dms,
    contents,
    parameters,
    fields
   FROM sw.t_scripts;


ALTER VIEW sw.v_pipeline_script_entry OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_script_entry; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_script_entry TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_script_entry TO writeaccess;

