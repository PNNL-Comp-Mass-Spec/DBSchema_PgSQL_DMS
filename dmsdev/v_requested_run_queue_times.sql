--
-- Name: v_requested_run_queue_times; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_queue_times AS
 SELECT requested_run_id,
    requested_run_created,
    requested_run_name,
    origin,
    batch_id,
    dataset_id,
    dataset_created,
    dataset_acqtimestart AS dataset_acq_time_start,
        CASE
            WHEN (days_from_requested_run_create_to_dataset_acquired IS NULL) THEN
            CASE
                WHEN (state_name OPERATOR(public.=) 'Active'::public.citext) THEN round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (requested_run_created)::timestamp with time zone)) / (86400)::numeric))
                ELSE NULL::numeric
            END
            WHEN (days_from_requested_run_create_to_dataset_acquired <= (0)::numeric) THEN
            CASE
                WHEN (origin OPERATOR(public.=) 'Auto'::public.citext) THEN NULL::numeric
                ELSE days_from_requested_run_create_to_dataset_acquired
            END
            ELSE days_from_requested_run_create_to_dataset_acquired
        END AS days_in_queue
   FROM ( SELECT rr.request_id AS requested_run_id,
            rr.created AS requested_run_created,
            rr.request_name AS requested_run_name,
            rr.batch_id,
            rr.state_name,
            rr.origin,
            ds.dataset_id,
            ds.created AS dataset_created,
            ds.acq_time_start AS dataset_acqtimestart,
            round((EXTRACT(epoch FROM (COALESCE(ds.acq_time_start, ds.created) - rr.created)) / (86400)::numeric)) AS days_from_requested_run_create_to_dataset_acquired
           FROM (public.t_requested_run rr
             LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))) dataq;


ALTER VIEW public.v_requested_run_queue_times OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_queue_times; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_queue_times TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_queue_times TO writeaccess;

