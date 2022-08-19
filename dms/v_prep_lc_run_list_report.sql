--
-- Name: v_prep_lc_run_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_run_list_report AS
 SELECT preprun.prep_run_id AS id,
    preprun.tab,
    preprun.instrument,
    preprun.type,
    preprun.lc_column,
    preprun.comment,
    preprun.guard_column,
    preprun.quality_control AS qc,
    preprun.created,
    preprun.operator_prn,
    preprun.digestion_method,
    preprun.sample_type,
    preprun.sample_prep_request,
    preprun.number_of_runs,
    preprun.instrument_pressure
   FROM public.t_prep_lc_run preprun;


ALTER TABLE public.v_prep_lc_run_list_report OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_run_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_run_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_run_list_report TO writeaccess;

