--
-- Name: v_get_pipeline_settings_files_as_text; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_settings_files_as_text AS
 SELECT t_settings_files.settings_file_id AS id,
    t_settings_files.analysis_tool,
    t_settings_files.file_name,
    t_settings_files.description,
    t_settings_files.active,
    t_settings_files.last_updated,
    (t_settings_files.contents)::text AS contents,
    t_settings_files.job_usage_count
   FROM public.t_settings_files;


ALTER TABLE public.v_get_pipeline_settings_files_as_text OWNER TO d3l243;

--
-- Name: TABLE v_get_pipeline_settings_files_as_text; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_settings_files_as_text TO readaccess;
GRANT SELECT ON TABLE public.v_get_pipeline_settings_files_as_text TO writeaccess;

