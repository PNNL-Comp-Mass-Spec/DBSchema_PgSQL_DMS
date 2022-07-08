--
-- Name: v_requested_run_batch_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_detail_report AS
 SELECT rrb.batch_id AS id,
    rrb.batch AS name,
    rrb.description,
    public.get_batch_requested_run_list(rrb.batch_id) AS requests,
    COALESCE(fc.factor_count, (0)::bigint) AS factors,
    u.name_with_username AS owner,
    rrb.created,
    rrb.locked,
    rrb.last_ordered,
    rrb.requested_batch_priority,
    rrb.requested_completion_date,
    rrb.justification_for_high_priority,
    public.get_batch_dataset_instrument_list(rrb.batch_id) AS instrument_used,
    rrb.requested_instrument AS instrument_group,
    rrb.comment
   FROM ((public.t_requested_run_batches rrb
     JOIN public.t_users u ON ((rrb.owner = u.user_id)))
     LEFT JOIN public.v_factor_count_by_req_run_batch fc ON ((fc.batch_id = rrb.batch_id)));


ALTER TABLE public.v_requested_run_batch_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_detail_report TO readaccess;
