--
-- Name: v_dms_pipeline_jobs; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_pipeline_jobs AS
 SELECT job,
    priority,
    tool,
    dataset,
    dataset_id,
    settings_file_name,
    parameter_file_name,
    state,
    transfer_folder_path,
    comment,
    special_processing,
    owner
   FROM public.v_get_pipeline_jobs;


ALTER VIEW sw.v_dms_pipeline_jobs OWNER TO d3l243;

--
-- Name: TABLE v_dms_pipeline_jobs; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_pipeline_jobs TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_pipeline_jobs TO writeaccess;

