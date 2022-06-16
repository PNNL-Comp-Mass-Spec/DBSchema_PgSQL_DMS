--
-- Name: v_requested_run_batch_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_list_report AS
 SELECT rrb.batch_id AS id,
    rrb.batch AS name,
    activereqseptypes.requests,
    completedrequests.runs,
    spq.blocked,
    spq.blkmissing,
    activereqstats.first_request,
    activereqstats.last_request,
    rrb.requested_batch_priority AS req_priority,
        CASE
            WHEN (completedrequests.runs > 0) THEN
            CASE
                WHEN (completedrequests.instrumentfirst OPERATOR(public.=) completedrequests.instrumentlast) THEN (completedrequests.instrumentfirst)::text
                ELSE (((completedrequests.instrumentfirst)::text || ' - '::text) || (completedrequests.instrumentlast)::text)
            END
            ELSE ''::text
        END AS instrument,
    rrb.requested_instrument AS inst_group,
    rrb.description,
    t_users.name AS owner,
    rrb.created,
        CASE
            WHEN (activereqseptypes.requests IS NULL) THEN completedrequests.maxdaysinqueue
            ELSE round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (COALESCE(activereqstats.oldest_request_created, completedrequests.oldest_request_created))::timestamp with time zone)) / (86400)::numeric))
        END AS days_in_queue,
    (rrb.requested_completion_date)::date AS complete_by,
    spq.days_in_prep_queue,
    rrb.justification_for_high_priority,
    rrb.comment,
        CASE
            WHEN (activereqseptypes.separationtypefirst OPERATOR(public.=) activereqseptypes.separationtypelast) THEN (activereqseptypes.separationtypefirst)::text
            ELSE (((activereqseptypes.separationtypefirst)::text || ' - '::text) || (activereqseptypes.separationtypelast)::text)
        END AS separation_type,
        CASE
            WHEN (activereqseptypes.requests IS NULL) THEN 0
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (activereqstats.oldest_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (30)::numeric) THEN 30
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (activereqstats.oldest_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (60)::numeric) THEN 60
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (activereqstats.oldest_request_created)::timestamp with time zone)) / (86400)::numeric)) <= (90)::numeric) THEN 90
            ELSE 120
        END AS "#DaysInQueue"
   FROM (((((public.t_requested_run_batches rrb
     JOIN public.t_users ON ((rrb.owner = t_users.user_id)))
     LEFT JOIN ( SELECT rr1.batch_id AS batchid,
            public.min(rr1.separation_group) AS separationtypefirst,
            public.max(rr1.separation_group) AS separationtypelast,
            count(*) AS requests
           FROM public.t_requested_run rr1
          WHERE (rr1.state_name OPERATOR(public.=) 'Active'::public.citext)
          GROUP BY rr1.batch_id) activereqseptypes ON ((activereqseptypes.batchid = rrb.batch_id)))
     LEFT JOIN ( SELECT rr2.batch_id AS batchid,
            count(*) AS runs,
            min(rr2.created) AS oldest_request_created,
            min(qt.days_in_queue) AS mindaysinqueue,
            max(qt.days_in_queue) AS maxdaysinqueue,
            public.min(instname.instrument) AS instrumentfirst,
            public.max(instname.instrument) AS instrumentlast
           FROM (((public.t_requested_run rr2
             JOIN public.v_requested_run_queue_times qt ON ((qt.requested_run_id = rr2.request_id)))
             JOIN public.t_dataset ds ON ((rr2.dataset_id = ds.dataset_id)))
             JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
          WHERE (NOT (rr2.dataset_id IS NULL))
          GROUP BY rr2.batch_id) completedrequests ON ((completedrequests.batchid = rrb.batch_id)))
     LEFT JOIN ( SELECT rr3.batch_id AS batchid,
            min(rr3.request_id) AS first_request,
            max(rr3.request_id) AS last_request,
            min(rr3.created) AS oldest_request_created
           FROM public.t_requested_run rr3
          WHERE ((rr3.dataset_id IS NULL) AND (rr3.state_name OPERATOR(public.=) 'Active'::public.citext))
          GROUP BY rr3.batch_id) activereqstats ON ((activereqstats.batchid = rrb.batch_id)))
     LEFT JOIN ( SELECT rr4.batch_id AS batchid,
            max(qt.days_in_queue) AS days_in_prep_queue,
            sum(
                CASE
                    WHEN ((COALESCE(spr.block_and_randomize_runs, ''::bpchar) = 'yes'::bpchar) AND ((COALESCE(rr4.block, 0) = 0) OR (COALESCE(rr4.run_order, 0) = 0))) THEN 1
                    ELSE 0
                END) AS blkmissing,
            sum(
                CASE
                    WHEN ((COALESCE(rr4.block, 0) > 0) AND (COALESCE(rr4.run_order, 0) > 0)) THEN 1
                    ELSE 0
                END) AS blocked
           FROM (((public.t_requested_run rr4
             JOIN public.t_experiments e ON ((rr4.exp_id = e.exp_id)))
             LEFT JOIN public.t_sample_prep_request spr ON (((e.sample_prep_request_id = spr.prep_request_id) AND (spr.prep_request_id <> 0))))
             LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
          GROUP BY rr4.batch_id) spq ON ((spq.batchid = rrb.batch_id)))
  WHERE (rrb.batch_id > 0);


ALTER TABLE public.v_requested_run_batch_list_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_list_report TO readaccess;

