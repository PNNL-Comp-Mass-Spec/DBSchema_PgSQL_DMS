--
-- Name: v_requested_run_batch_group_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_group_list_report AS
 SELECT bg.batch_group_id AS id,
    bg.batch_group AS name,
    public.get_batch_group_member_list(bg.batch_group_id) AS batches,
    statsq.requests,
    statsq.first_request,
    statsq.last_request,
    (public.get_batch_group_instrument_group_list(bg.batch_group_id))::public.citext AS instrument_group,
    bg.description,
    t_users.name AS owner,
    bg.created
   FROM ((public.t_requested_run_batch_group bg
     LEFT JOIN public.t_users ON ((bg.owner_user_id = t_users.user_id)))
     LEFT JOIN ( SELECT rrb1.batch_group_id,
            count(rr1.request_id) AS requests,
            min(rr1.request_id) AS first_request,
            max(rr1.request_id) AS last_request,
            min(rr1.created) AS oldest_request_created
           FROM (public.t_requested_run rr1
             JOIN public.t_requested_run_batches rrb1 ON ((rr1.batch_id = rrb1.batch_id)))
          WHERE (NOT (rrb1.batch_group_id IS NULL))
          GROUP BY rrb1.batch_group_id) statsq ON ((bg.batch_group_id = statsq.batch_group_id)));


ALTER VIEW public.v_requested_run_batch_group_list_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_group_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_group_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_group_list_report TO writeaccess;

