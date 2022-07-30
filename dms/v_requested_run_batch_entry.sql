--
-- Name: v_requested_run_batch_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_entry AS
 SELECT rrb.batch_id AS id,
    rrb.batch AS name,
    rrb.description,
    public.get_batch_requested_run_list(rrb.batch_id) AS requested_run_list,
    u.username AS owner_prn,
    rrb.requested_batch_priority,
    rrb.requested_completion_date,
    rrb.justification_for_high_priority AS justification_high_priority,
    rrb.requested_instrument,
    rrb.comment
   FROM (public.t_requested_run_batches rrb
     JOIN public.t_users u ON ((rrb.owner = u.user_id)));


ALTER TABLE public.v_requested_run_batch_entry OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_entry TO readaccess;
