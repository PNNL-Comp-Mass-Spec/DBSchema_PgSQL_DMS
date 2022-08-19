--
-- Name: v_requested_run_unified_list_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_unified_list_ex AS
 SELECT rr.request_id AS request,
    rr.request_name AS name,
    rr.state_name AS status,
    rr.batch_id AS batch,
    e.experiment,
    rr.exp_id AS experiment_id,
    rr.instrument_group AS instrument,
    ds.dataset,
    rr.dataset_id,
    rr.block,
    rr.run_order,
    lc.cart_name AS cart,
    rr.cart_column AS lc_col
   FROM ((public.t_lc_cart lc
     JOIN (public.t_requested_run rr
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id))) ON ((lc.cart_id = rr.cart_id)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)));


ALTER TABLE public.v_requested_run_unified_list_ex OWNER TO d3l243;

--
-- Name: VIEW v_requested_run_unified_list_ex; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_requested_run_unified_list_ex IS 'This view is used by function Make_Factor_Crosstab_SQL_Ex, which is used by function Get_Requested_Run_Parameters_And_Factors';

--
-- Name: TABLE v_requested_run_unified_list_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_unified_list_ex TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_unified_list_ex TO writeaccess;

