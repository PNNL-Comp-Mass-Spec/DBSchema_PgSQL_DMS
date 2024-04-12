--
-- Name: v_analysis_date_completed; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_date_completed AS
 SELECT j.job,
    j.job_state_id AS state,
    EXTRACT(year FROM j.finish) AS y,
    EXTRACT(month FROM j.finish) AS m,
    EXTRACT(day FROM j.finish) AS d,
    t.analysis_tool AS tool
   FROM (public.t_analysis_job j
     JOIN public.t_analysis_tool t ON ((j.analysis_tool_id = t.analysis_tool_id)));


ALTER VIEW public.v_analysis_date_completed OWNER TO d3l243;

--
-- Name: TABLE v_analysis_date_completed; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_date_completed TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_date_completed TO writeaccess;

