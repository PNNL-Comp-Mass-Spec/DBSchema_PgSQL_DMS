--
-- Name: v_requested_run_batch_group_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_group_detail_report AS
 SELECT bg.batch_group_id AS id,
    bg.batch_group AS name,
    bg.description,
    public.get_batch_group_member_list(bg.batch_group_id) AS batches,
    public.get_batch_group_requested_run_list(bg.batch_group_id) AS requests,
    u.name_with_username AS owner,
    bg.created,
    public.get_batch_group_instrument_group_list(bg.batch_group_id) AS instrument_group
   FROM (public.t_requested_run_batch_group bg
     LEFT JOIN public.t_users u ON ((bg.owner_user_id = u.user_id)));


ALTER VIEW public.v_requested_run_batch_group_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_group_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_group_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_group_detail_report TO writeaccess;

