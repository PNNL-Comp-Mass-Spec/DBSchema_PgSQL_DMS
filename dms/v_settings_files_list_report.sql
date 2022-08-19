--
-- Name: v_settings_files_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_settings_files_list_report AS
 SELECT t_settings_files.settings_file_id AS id,
    t_settings_files.analysis_tool,
    t_settings_files.file_name,
    t_settings_files.description,
    t_settings_files.active,
    t_settings_files.job_usage_count AS jobs,
    t_settings_files.msgfplus_auto_centroid,
    t_settings_files.hms_auto_supersede
   FROM public.t_settings_files;


ALTER TABLE public.v_settings_files_list_report OWNER TO d3l243;

--
-- Name: TABLE v_settings_files_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_settings_files_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_settings_files_list_report TO writeaccess;

