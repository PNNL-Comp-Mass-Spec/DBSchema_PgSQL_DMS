--
-- Name: v_prep_lc_run_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_run_list_report AS
 SELECT prep_run_id AS id,
    prep_run_name AS name,
    instrument,
    type,
    lc_column,
    comment,
    guard_column,
    quality_control AS qc,
    created,
    operator_username,
    digestion_method,
    sample_type,
    sample_prep_requests,
    sample_prep_work_packages AS work_packages,
    number_of_runs,
    instrument_pressure
   FROM public.t_prep_lc_run preprun;


ALTER VIEW public.v_prep_lc_run_list_report OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_run_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_run_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_run_list_report TO writeaccess;

