--
-- Name: v_prep_lc_run_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_lc_run_entry AS
 SELECT prep_run_id AS id,
    prep_run_name,
    instrument,
    type,
    lc_column,
    lc_column_2,
    comment,
    guard_column,
    created,
    operator_username,
    digestion_method,
    sample_type,
    number_of_runs,
    instrument_pressure,
    sample_prep_requests,
    quality_control,
    public.get_hplc_run_dataset_list(prep_run_id, 'name'::text) AS datasets
   FROM public.t_prep_lc_run preprun;


ALTER VIEW public.v_prep_lc_run_entry OWNER TO d3l243;

--
-- Name: TABLE v_prep_lc_run_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_lc_run_entry TO readaccess;
GRANT SELECT ON TABLE public.v_prep_lc_run_entry TO writeaccess;

