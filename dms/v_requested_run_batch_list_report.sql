--
-- Name: v_requested_run_batch_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_list_report AS
 SELECT rrb.batch_id AS id,
    rrb.batch AS name,
    rbs.active_requests AS requests,
    rbs.datasets,
    rbs.blocked,
    rbs.block_missing,
    rbs.first_active_request,
    rbs.last_active_request,
    rrb.requested_batch_priority AS req_priority,
        CASE
            WHEN (COALESCE(rbs.datasets, 0) > 0) THEN
            CASE
                WHEN (rbs.instrument_first OPERATOR(public.=) rbs.instrument_last) THEN rbs.instrument_first
                ELSE ((((rbs.instrument_first)::text || ' - '::text) || (rbs.instrument_last)::text))::public.citext
            END
            ELSE ''::public.citext
        END AS instrument,
    rbs.instrument_group_first AS inst_group,
    rrb.description,
    rbs.work_package,
    rbs.eus_proposal_id,
    rbs.proposal_type,
    t_users.name AS owner,
    rrb.created,
    rbs.days_in_queue,
    (rrb.requested_completion_date)::date AS complete_by,
    rbs.days_in_prep_queue,
    rrb.justification_for_high_priority,
    rrb.comment,
        CASE
            WHEN (rbs.separation_group_first OPERATOR(public.=) rbs.separation_group_last) THEN rbs.separation_group_first
            ELSE ((((rbs.separation_group_first)::text || ' - '::text) || (rbs.separation_group_last)::text))::public.citext
        END AS separation_group,
    rrb.batch_group_id AS batch_group,
    rrb.batch_group_order,
        CASE
            WHEN (COALESCE(rbs.active_requests, 0) = 0) THEN 0
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (rbs.oldest_active_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (30)::numeric) THEN 30
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (rbs.oldest_active_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (60)::numeric) THEN 60
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (rbs.oldest_active_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin
   FROM ((public.t_requested_run_batches rrb
     LEFT JOIN public.t_users ON ((rrb.owner_user_id = t_users.user_id)))
     LEFT JOIN public.t_cached_requested_run_batch_stats rbs ON ((rrb.batch_id = rbs.batch_id)))
  WHERE (rrb.batch_id > 0);


ALTER VIEW public.v_requested_run_batch_list_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_list_report TO writeaccess;

