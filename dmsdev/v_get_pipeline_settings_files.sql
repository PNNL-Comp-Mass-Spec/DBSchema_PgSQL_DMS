--
-- Name: v_get_pipeline_settings_files; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_settings_files AS
 SELECT settings_file_id AS id,
    analysis_tool,
    file_name,
    description,
    active,
    last_updated,
    contents,
    job_usage_count
   FROM public.t_settings_files;


ALTER VIEW public.v_get_pipeline_settings_files OWNER TO d3l243;

--
-- Name: TABLE v_get_pipeline_settings_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_settings_files TO readaccess;
GRANT SELECT ON TABLE public.v_get_pipeline_settings_files TO writeaccess;

