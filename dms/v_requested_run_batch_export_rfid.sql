--
-- Name: v_requested_run_batch_export_rfid; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_export_rfid AS
 SELECT rrb.batch_id AS id,
    rrb.batch AS name,
    u.name AS owner,
    rrb.description,
    stats.requests,
    stats.active_requests,
    (rbs.instrument_group_first)::public.citext AS inst_group,
    rrb.created,
    rrb.rfid_hex_id AS hex_id
   FROM (((public.t_requested_run_batches rrb
     LEFT JOIN public.t_users u ON ((rrb.owner_user_id = u.user_id)))
     LEFT JOIN ( SELECT rr.batch_id,
            count(rr.request_id) AS requests,
            sum(
                CASE
                    WHEN (rr.state_name OPERATOR(public.=) ANY (ARRAY['Active'::public.citext, 'Holding'::public.citext])) THEN 1
                    ELSE 0
                END) AS active_requests
           FROM public.t_requested_run rr
          GROUP BY rr.batch_id) stats ON ((stats.batch_id = rrb.batch_id)))
     LEFT JOIN public.t_cached_requested_run_batch_stats rbs ON ((rbs.batch_id = rrb.batch_id)))
  WHERE (rrb.batch_id > 0);


ALTER VIEW public.v_requested_run_batch_export_rfid OWNER TO d3l243;

--
-- Name: VIEW v_requested_run_batch_export_rfid; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_requested_run_batch_export_rfid IS 'This view is used by the RFID scanner software that reads RFID tags on material containers in freezers. Requests is total requested runs in the batch. Active_Requests is the number of active requested runs in the batch (no dataset yet)';

--
-- Name: TABLE v_requested_run_batch_export_rfid; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_export_rfid TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_export_rfid TO writeaccess;

