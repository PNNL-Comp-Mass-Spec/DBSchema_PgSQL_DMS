--
-- Name: v_prep_lc_run_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_run_entry AS
 SELECT preprun.prep_run_id AS id,
    preprun.prep_run_name,
    preprun.instrument,
    preprun.type,
    preprun.lc_column,
    preprun.lc_column_2,
    preprun.comment,
    preprun.guard_column,
    preprun.created,
    preprun.operator_username,
    preprun.digestion_method,
    preprun.sample_type,
    preprun.number_of_runs,
    preprun.instrument_pressure,
    preprun.sample_prep_requests,
    preprun.quality_control,
    public.get_hplc_run_dataset_list(preprun.prep_run_id, 'name'::text) AS datasets
   FROM public.t_prep_lc_run preprun;


ALTER TABLE public.v_prep_lc_run_entry OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_run_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_run_entry TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_run_entry TO writeaccess;

