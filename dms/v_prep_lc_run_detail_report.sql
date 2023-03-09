--
-- Name: v_prep_lc_run_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_run_detail_report AS
 SELECT preprun.prep_run_id AS id,
    preprun.prep_run_name AS name,
    preprun.instrument,
    preprun.type,
    preprun.lc_column,
    preprun.lc_column_2,
    preprun.comment,
    preprun.guard_column,
    preprun.quality_control AS qc,
    preprun.created,
    preprun.operator_username,
    preprun.digestion_method,
    preprun.sample_type,
    preprun.sample_prep_requests,
    preprun.sample_prep_work_packages AS work_packages,
    preprun.number_of_runs,
    public.get_prep_lc_experiment_groups_list(preprun.prep_run_id) AS experiment_groups,
    preprun.instrument_pressure,
    public.get_hplc_run_dataset_list(preprun.prep_run_id, 'name'::text) AS datasets
   FROM public.t_prep_lc_run preprun;


ALTER TABLE public.v_prep_lc_run_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_run_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_run_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_run_detail_report TO writeaccess;

