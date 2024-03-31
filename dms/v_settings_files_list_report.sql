--
-- Name: v_settings_files_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_settings_files_list_report AS
 SELECT settings_file_id AS id,
    analysis_tool,
    file_name,
    description,
    active,
    job_usage_count AS jobs,
    msgfplus_auto_centroid,
    hms_auto_supersede
   FROM public.t_settings_files;


ALTER VIEW public.v_settings_files_list_report OWNER TO d3l243;

--
-- Name: TABLE v_settings_files_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_settings_files_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_settings_files_list_report TO writeaccess;

