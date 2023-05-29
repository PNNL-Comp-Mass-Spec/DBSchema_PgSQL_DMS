--
-- Name: v_requested_run_batch_location_history_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_location_history_list_report AS
 SELECT h.batch_id,
    rrb.batch AS batch_name,
    u.name AS batch_owner,
    rrb.created AS batch_created,
    f.freezer,
    h.first_scan_date,
    h.last_scan_date,
        CASE
            WHEN (h.last_scan_date IS NULL) THEN (0)::numeric
            ELSE EXTRACT(day FROM (h.last_scan_date - h.first_scan_date))
        END AS days_in_freezer
   FROM ((((public.t_requested_run_batch_location_history h
     JOIN public.t_material_locations ml ON ((ml.location_id = h.location_id)))
     JOIN public.t_requested_run_batches rrb ON ((h.batch_id = rrb.batch_id)))
     JOIN public.t_material_freezers f ON ((ml.freezer_tag OPERATOR(public.=) f.freezer_tag)))
     JOIN public.t_users u ON ((rrb.owner_user_id = u.user_id)));


ALTER TABLE public.v_requested_run_batch_location_history_list_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_location_history_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_location_history_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_location_history_list_report TO writeaccess;

