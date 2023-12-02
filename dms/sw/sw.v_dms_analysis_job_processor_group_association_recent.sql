--
-- Name: v_dms_analysis_job_processor_group_association_recent; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_analysis_job_processor_group_association_recent AS
 SELECT v_analysis_job_processor_group_association_recent.group_name,
    v_analysis_job_processor_group_association_recent.job,
    v_analysis_job_processor_group_association_recent.state,
    v_analysis_job_processor_group_association_recent.dataset,
    v_analysis_job_processor_group_association_recent.tool,
    v_analysis_job_processor_group_association_recent.param_file,
    v_analysis_job_processor_group_association_recent.settings_file
   FROM public.v_analysis_job_processor_group_association_recent;


ALTER VIEW sw.v_dms_analysis_job_processor_group_association_recent OWNER TO d3l243;

--
-- Name: TABLE v_dms_analysis_job_processor_group_association_recent; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_analysis_job_processor_group_association_recent TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_analysis_job_processor_group_association_recent TO writeaccess;

