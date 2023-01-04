--
-- Name: v_param_file_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_picklist AS
 SELECT pf.param_file_name AS name,
    pf.param_file_description AS "desc",
    COALESCE(pf.job_usage_last_year, 0) AS job_count,
    COALESCE(pf.job_usage_count, 0) AS jobs_all_time,
    pf.param_file_id AS id,
    tool.analysis_tool AS tool_name,
        CASE
            WHEN (COALESCE(pf.job_usage_last_year, 0) > 0) THEN (pf.job_usage_last_year + 1000000)
            ELSE COALESCE(pf.job_usage_count, 0)
        END AS sort_key
   FROM (public.t_param_files pf
     JOIN public.t_analysis_tool tool ON ((pf.param_file_type_id = tool.param_file_type_id)))
  WHERE (pf.valid = 1);


ALTER TABLE public.v_param_file_picklist OWNER TO d3l243;

--
-- Name: TABLE v_param_file_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_param_file_picklist TO writeaccess;

