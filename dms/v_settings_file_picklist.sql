--
-- Name: v_settings_file_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_settings_file_picklist AS
 SELECT filterq.file_name,
    filterq.description,
    filterq.job_count,
    filterq.jobs_all_time,
    filterq.analysis_tool,
        CASE
            WHEN (filterq.job_count > 0) THEN (filterq.job_count + 1000000)
            ELSE filterq.jobs_all_time
        END AS sort_key
   FROM ( SELECT sf.file_name,
            sf.description,
            COALESCE(sf.job_usage_last_year, 0) AS job_count,
            COALESCE(sf.job_usage_count, 0) AS jobs_all_time,
            sf.analysis_tool
           FROM (public.t_settings_files sf
             JOIN public.t_analysis_tool antool ON ((sf.analysis_tool OPERATOR(public.=) antool.analysis_tool)))
          WHERE (sf.active <> 0)
        UNION
         SELECT sf.file_name,
            sf.description,
            COALESCE(sf.job_usage_last_year, 0) AS job_count,
            COALESCE(sf.job_usage_count, 0) AS jobs_all_time,
            antool.analysis_tool
           FROM (public.t_settings_files sf
             JOIN public.t_analysis_tool antool ON ((sf.analysis_tool OPERATOR(public.=) antool.tool_base_name)))
          WHERE (sf.active <> 0)) filterq;


ALTER VIEW public.v_settings_file_picklist OWNER TO d3l243;

--
-- Name: TABLE v_settings_file_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_settings_file_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_settings_file_picklist TO writeaccess;

