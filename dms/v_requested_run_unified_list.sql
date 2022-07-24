--
-- Name: v_requested_run_unified_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_unified_list AS
 SELECT rr.request_id AS request,
    rr.request_name AS name,
    rr.batch_id,
    rrb.batch AS batch_name,
    rr.dataset_id,
    d.dataset,
    rr.exp_id AS experiment_id,
    e.experiment,
    rr.state_name AS status,
    rr.block,
    rr.run_order
   FROM (((public.t_requested_run rr
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     LEFT JOIN public.t_dataset d ON ((rr.dataset_id = d.dataset_id)))
     LEFT JOIN public.t_requested_run_batches rrb ON ((rr.batch_id = rrb.batch_id)));


ALTER TABLE public.v_requested_run_unified_list OWNER TO d3l243;

--
-- Name: VIEW v_requested_run_unified_list; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_requested_run_unified_list IS 'This view is used by function Make_Factor_Crosstab_SQL, which is used by functions Get_Factor_Crosstab_By_Batch, Get_Requested_Run_Factors_For_Edit, and Get_Requested_RunFactors_For_Export';

--
-- Name: TABLE v_requested_run_unified_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_unified_list TO readaccess;

