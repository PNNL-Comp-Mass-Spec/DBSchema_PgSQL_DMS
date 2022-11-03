--
-- Name: v_run_planning_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_planning_report AS
 SELECT groupq.inst_group,
    groupq.ds_type,
        CASE
            WHEN (groupq.fraction_count > 1) THEN (groupq.run_count * groupq.fraction_count)
            ELSE groupq.run_count
        END AS run_count,
    groupq.blocked,
    groupq.blkmissing,
        CASE
            WHEN (requestlookupq.batch_id > 0) THEN groupq.batch_prefix
            ELSE groupq.request_prefix
        END AS request_or_batch_name,
    requestlookupq.batch_id AS batch,
    groupq.requester,
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (groupq.date_created)::timestamp with time zone)) / (86400)::numeric)) AS days_in_queue,
    groupq.days_in_prep_queue,
    groupq.queue_state,
    groupq.queued_instrument,
    groupq.separation_group,
        CASE
            WHEN (requestlookupq.batch_id > 0) THEN groupq.batch_comment
            ELSE requestlookupq.comment
        END AS comment,
    groupq.min_request,
    groupq.work_package,
    groupq.wp_state,
    groupq.proposal,
    groupq.proposal_type,
    teut.eus_usage_type AS usage,
    groupq.locked,
    groupq.last_ordered,
    groupq.request_name_code,
        CASE
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (groupq.date_created)::timestamp with time zone)) / (86400)::numeric)) <= (30)::numeric) THEN 30
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (groupq.date_created)::timestamp with time zone)) / (86400)::numeric)) <= (60)::numeric) THEN 60
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (groupq.date_created)::timestamp with time zone)) / (86400)::numeric)) <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin,
    groupq.wp_activation_state,
    groupq.requested_batch_priority AS batch_priority,
        CASE
            WHEN (groupq.fraction_count > 1) THEN 1
            WHEN (groupq.fractionbasedrequestcount > 1) THEN 2
            ELSE 0
        END AS fraction_color_mode
   FROM ((( SELECT requestq.inst_group,
            min(requestq.requestid) AS min_request,
            count(requestq.requestid) AS run_count,
            min(requestq.request_prefix) AS request_prefix,
            requestq.requester,
            min(requestq.request_created) AS date_created,
            requestq.separation_group,
            requestq.fraction_count,
            requestq.ds_type,
            requestq.work_package,
            requestq.wp_state,
            requestq.wp_activation_state,
            requestq.proposal,
            requestq.proposal_type,
            requestq.locked,
            requestq.batch_prefix,
            requestq.requested_batch_priority,
            requestq.batch_comment,
            requestq.last_ordered,
            requestq.queue_state,
            requestq.queued_instrument,
            requestq.request_name_code,
            sum(
                CASE
                    WHEN (requestq.requestorigin OPERATOR(public.=) 'fraction'::public.citext) THEN 1
                    ELSE 0
                END) AS fractionbasedrequestcount,
            max(requestq.days_in_prep_queue) AS days_in_prep_queue,
            sum(requestq.blkmissing) AS blkmissing,
            sum(requestq.blocked) AS blocked
           FROM ( SELECT rr.instrument_group AS inst_group,
                    rr.separation_group,
                    dtn.dataset_type AS ds_type,
                    rr.request_id AS requestid,
                    ("left"((rr.request_name)::text, 20) ||
                        CASE
                            WHEN (char_length((rr.request_name)::text) > 20) THEN '...'::text
                            ELSE ''::text
                        END) AS request_prefix,
                    rr.request_name_code,
                    rr.origin AS requestorigin,
                    u.name AS requester,
                    rr.created AS request_created,
                    rr.work_package,
                    COALESCE(cc.activation_state_name, ''::public.citext) AS wp_state,
                    cc.activation_state AS wp_activation_state,
                    rr.eus_proposal_id AS proposal,
                    ept.abbreviation AS proposal_type,
                    rrb.locked,
                    rrb.requested_batch_priority,
                    rr.batch_id AS batch,
                    rrb.comment AS batch_comment,
                    qs.queue_state_name AS queue_state,
                        CASE
                            WHEN (rr.queue_state = 2) THEN COALESCE(assignedinstrument.instrument, ''::public.citext)
                            ELSE ''::public.citext
                        END AS queued_instrument,
                    ("left"((rrb.batch)::text, 20) ||
                        CASE
                            WHEN (char_length((rrb.batch)::text) > 20) THEN '...'::text
                            ELSE ''::text
                        END) AS batch_prefix,
                    (rrb.last_ordered)::date AS last_ordered,
                        CASE
                            WHEN (spr.prep_request_id = 0) THEN NULL::numeric
                            ELSE qt.days_in_queue
                        END AS days_in_prep_queue,
                        CASE
                            WHEN ((COALESCE(spr.block_and_randomize_runs, ''::bpchar) = 'yes'::bpchar) AND ((COALESCE(rr.block, 0) = 0) OR (COALESCE(rr.run_order, 0) = 0))) THEN 1
                            ELSE 0
                        END AS blkmissing,
                        CASE
                            WHEN ((COALESCE(rr.block, 0) > 0) AND (COALESCE(rr.run_order, 0) > 0)) THEN 1
                            ELSE 0
                        END AS blocked,
                    sg.fraction_count
                   FROM (((((((((((((public.t_dataset_type_name dtn
                     JOIN public.t_requested_run rr ON ((dtn.dataset_type_id = rr.request_type_id)))
                     JOIN public.t_users u ON ((rr.requester_prn OPERATOR(public.=) u.username)))
                     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
                     JOIN public.t_requested_run_queue_state qs ON ((rr.queue_state = qs.queue_state)))
                     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
                     JOIN public.t_requested_run_batches rrb ON ((rr.batch_id = rrb.batch_id)))
                     JOIN public.t_sample_prep_request spr ON ((e.sample_prep_request_id = spr.prep_request_id)))
                     JOIN public.t_separation_group sg ON ((rr.separation_group OPERATOR(public.=) sg.separation_group)))
                     LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
                     LEFT JOIN public.v_charge_code_status cc ON ((rr.work_package OPERATOR(public.=) cc.charge_code)))
                     LEFT JOIN public.t_eus_proposals eup ON ((rr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
                     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
                     LEFT JOIN public.t_instrument_name assignedinstrument ON ((rr.queue_instrument_id = assignedinstrument.instrument_id)))
                  WHERE ((rr.state_name OPERATOR(public.=) 'Active'::public.citext) AND (rr.dataset_id IS NULL))) requestq
          GROUP BY requestq.inst_group, requestq.separation_group, requestq.fraction_count, requestq.ds_type, requestq.request_name_code, requestq.requester, requestq.work_package, requestq.wp_state, requestq.wp_activation_state, requestq.proposal, requestq.proposal_type, requestq.locked, requestq.last_ordered, requestq.queue_state, requestq.queued_instrument, requestq.batch, requestq.batch_prefix, requestq.requested_batch_priority, requestq.batch_comment) groupq
     JOIN public.t_requested_run requestlookupq ON ((groupq.min_request = requestlookupq.request_id)))
     JOIN public.t_eus_usage_type teut ON ((requestlookupq.eus_usage_type_id = teut.eus_usage_type_id)));


ALTER TABLE public.v_run_planning_report OWNER TO d3l243;

--
-- Name: TABLE v_run_planning_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_planning_report TO readaccess;
GRANT SELECT ON TABLE public.v_run_planning_report TO writeaccess;

