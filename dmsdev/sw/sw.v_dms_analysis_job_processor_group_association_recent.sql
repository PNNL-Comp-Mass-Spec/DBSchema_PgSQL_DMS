--
-- Name: v_dms_analysis_job_processor_group_association_recent; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_analysis_job_processor_group_association_recent AS
 SELECT group_name,
    job,
    state,
    dataset,
    tool,
    param_file,
    settings_file
   FROM public.v_analysis_job_processor_group_association_recent;


ALTER VIEW sw.v_dms_analysis_job_processor_group_association_recent OWNER TO d3l243;

--
-- Name: TABLE v_dms_analysis_job_processor_group_association_recent; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_analysis_job_processor_group_association_recent TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_analysis_job_processor_group_association_recent TO writeaccess;

