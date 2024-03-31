--
-- Name: v_analysis_date_scheduled; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_date_scheduled AS
 SELECT job,
    job_state_id AS state,
    EXTRACT(year FROM created) AS y,
    EXTRACT(month FROM created) AS m,
    EXTRACT(day FROM created) AS d
   FROM public.t_analysis_job;


ALTER VIEW public.v_analysis_date_scheduled OWNER TO d3l243;

--
-- Name: TABLE v_analysis_date_scheduled; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_date_scheduled TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_date_scheduled TO writeaccess;

