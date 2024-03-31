--
-- Name: v_run_interval_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_interval_entry AS
 SELECT dataset_id AS id,
    instrument,
    entered,
    start,
    "interval",
    comment
   FROM public.t_run_interval;


ALTER VIEW public.v_run_interval_entry OWNER TO d3l243;

--
-- Name: TABLE v_run_interval_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_interval_entry TO readaccess;
GRANT SELECT ON TABLE public.v_run_interval_entry TO writeaccess;

