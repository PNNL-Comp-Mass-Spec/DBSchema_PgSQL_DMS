--
-- Name: v_pipeline_script_list_report; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_pipeline_script_list_report AS
 SELECT t_scripts.script,
    t_scripts.description,
    t_scripts.enabled,
    t_scripts.results_tag,
    t_scripts.script_id AS id,
        CASE
            WHEN (t_scripts.backfill_to_dms = 0) THEN 'N'::public.citext
            ELSE 'Y'::public.citext
        END AS backfill_to_dms
   FROM sw.t_scripts;


ALTER VIEW sw.v_pipeline_script_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pipeline_script_list_report; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_pipeline_script_list_report TO readaccess;
GRANT SELECT ON TABLE sw.v_pipeline_script_list_report TO writeaccess;

