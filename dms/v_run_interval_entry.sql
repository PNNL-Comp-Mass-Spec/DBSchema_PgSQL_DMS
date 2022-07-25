--
-- Name: v_run_interval_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_interval_entry AS
 SELECT t_run_interval.interval_id AS id,
    t_run_interval.instrument,
    t_run_interval.entered,
    t_run_interval.start,
    t_run_interval."interval",
    t_run_interval.comment
   FROM public.t_run_interval;


ALTER TABLE public.v_run_interval_entry OWNER TO d3l243;

--
-- Name: TABLE v_run_interval_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_interval_entry TO readaccess;

