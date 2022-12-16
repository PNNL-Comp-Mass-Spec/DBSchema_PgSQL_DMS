--
-- Name: v_dms_pipeline_jobs; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_pipeline_jobs AS
 SELECT v_get_pipeline_jobs.job,
    v_get_pipeline_jobs.priority,
    v_get_pipeline_jobs.tool,
    v_get_pipeline_jobs.dataset,
    v_get_pipeline_jobs.dataset_id,
    v_get_pipeline_jobs.settings_file_name,
    v_get_pipeline_jobs.parameter_file_name,
    v_get_pipeline_jobs.state,
    v_get_pipeline_jobs.transfer_folder_path,
    v_get_pipeline_jobs.comment,
    v_get_pipeline_jobs.special_processing,
    v_get_pipeline_jobs.owner
   FROM public.v_get_pipeline_jobs;


ALTER TABLE sw.v_dms_pipeline_jobs OWNER TO d3l243;

--
-- Name: TABLE v_dms_pipeline_jobs; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_pipeline_jobs TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_pipeline_jobs TO writeaccess;

