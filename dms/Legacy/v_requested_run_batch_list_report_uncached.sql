--
-- Name: v_requested_run_batch_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_list_report_uncached AS
 SELECT rrb.batch_id AS id,
    rrb.batch AS name,
    active_req_runs.requests,
    completed_requests.runs,
    spq.blocked,
    spq.block_missing,
    active_req_runs.first_request,
    active_req_runs.last_request,
    rrb.requested_batch_priority AS req_priority,
        CASE
            WHEN (completed_requests.runs > 0) THEN
            CASE
                WHEN (completed_requests.instrumentfirst OPERATOR(public.=) completed_requests.instrumentlast) THEN (completed_requests.instrumentfirst)::public.citext
                ELSE (((completed_requests.instrumentfirst)::public.citext || ' - '::public.citext) || (completed_requests.instrumentlast)::public.citext)
            END
            ELSE ''::public.citext
        END AS instrument,
    rrb.requested_instrument_group AS inst_group,
    rrb.description,
    t_users.name AS owner,
    rrb.created,
        CASE
            WHEN (active_req_runs.requests IS NULL) THEN completed_requests.max_days_in_queue
            ELSE round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (COALESCE(active_req_runs.oldest_request_created, completed_requests.oldest_request_created))::timestamp with time zone)) / (86400)::numeric))
        END AS days_in_queue,
    (rrb.requested_completion_date)::date AS complete_by,
    spq.days_in_prep_queue,
    rrb.justification_for_high_priority,
    rrb.comment,
        CASE
            WHEN (active_req_runs.separation_group_first OPERATOR(public.=) active_req_runs.separation_group_last) THEN (active_req_runs.separation_group_first)::public.citext
            ELSE (((active_req_runs.separation_group_first)::public.citext || ' - '::public.citext) || (active_req_runs.separation_group_last)::public.citext)
        END AS separation_group,
        CASE
            WHEN (active_req_runs.requests IS NULL) THEN 0
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (active_req_runs.oldest_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (30)::numeric) THEN 30
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (active_req_runs.oldest_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (60)::numeric) THEN 60
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (active_req_runs.oldest_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin
   FROM ((((public.t_requested_run_batches rrb
     LEFT JOIN public.t_users ON ((rrb.owner_user_id = t_users.user_id)))
     LEFT JOIN ( SELECT rr1.batch_id AS batchid,
            public.min(rr1.separation_group) AS separation_group_first,
            public.max(rr1.separation_group) AS separation_group_last,
            count(rr1.request_id) AS requests,
            min(rr1.request_id) AS first_request,
            max(rr1.request_id) AS last_request,
            min(rr1.created) AS oldest_request_created
           FROM public.t_requested_run rr1
          WHERE (rr1.state_name OPERATOR(public.=) 'Active'::public.citext)
          GROUP BY rr1.batch_id) active_req_runs ON ((active_req_runs.batchid = rrb.batch_id)))
     LEFT JOIN ( SELECT rr2.batch_id AS batchid,
            count(rr2.request_id) AS runs,
            min(rr2.created) AS oldest_request_created,
            max(qt.days_in_queue) AS max_days_in_queue,
            public.min(instname.instrument) AS instrumentfirst,
            public.max(instname.instrument) AS instrumentlast
           FROM (((public.t_requested_run rr2
             JOIN public.v_requested_run_queue_times qt ON ((qt.requested_run_id = rr2.request_id)))
             JOIN public.t_dataset ds ON ((rr2.dataset_id = ds.dataset_id)))
             JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
          WHERE (NOT (rr2.dataset_id IS NULL))
          GROUP BY rr2.batch_id) completed_requests ON ((completed_requests.batchid = rrb.batch_id)))
     LEFT JOIN ( SELECT rr3.batch_id AS batchid,
            max(qt.days_in_queue) AS days_in_prep_queue,
            sum(
                CASE
                    WHEN ((COALESCE(spr.block_and_randomize_runs, ''::public.citext) = 'yes'::public.citext) AND ((COALESCE(rr3.block, 0) = 0) OR (COALESCE(rr3.run_order, 0) = 0))) THEN 1
                    ELSE 0
                END) AS block_missing,
            sum(
                CASE
                    WHEN ((COALESCE(rr3.block, 0) > 0) AND (COALESCE(rr3.run_order, 0) > 0)) THEN 1
                    ELSE 0
                END) AS blocked
           FROM (((public.t_requested_run rr3
             JOIN public.t_experiments e ON ((rr3.exp_id = e.exp_id)))
             LEFT JOIN public.t_sample_prep_request spr ON (((e.sample_prep_request_id = spr.prep_request_id) AND (spr.prep_request_id <> 0))))
             LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
          GROUP BY rr3.batch_id) spq ON ((spq.batchid = rrb.batch_id)))
  WHERE (rrb.batch_id > 0);


ALTER TABLE public.v_requested_run_batch_list_report_uncached OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_list_report_uncached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_list_report_uncached TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_list_report_uncached TO writeaccess;

