--
-- Name: v_analysis_processor_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_processor_picklist AS
 SELECT processor_name AS val,
    ''::text AS ex
   FROM public.t_analysis_job_processors
  WHERE (state OPERATOR(public.=) 'E'::public.citext);


ALTER VIEW public.v_analysis_processor_picklist OWNER TO d3l243;

--
-- Name: TABLE v_analysis_processor_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_processor_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_processor_picklist TO writeaccess;

