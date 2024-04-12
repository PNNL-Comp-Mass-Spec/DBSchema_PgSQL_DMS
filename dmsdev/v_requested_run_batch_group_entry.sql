--
-- Name: v_requested_run_batch_group_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_group_entry AS
 SELECT bg.batch_group_id AS id,
    bg.batch_group AS name,
    bg.description,
    public.get_batch_group_member_list(bg.batch_group_id) AS requested_run_batch_list,
    u.username AS owner_username
   FROM (public.t_requested_run_batch_group bg
     LEFT JOIN public.t_users u ON ((bg.owner_user_id = u.user_id)));


ALTER VIEW public.v_requested_run_batch_group_entry OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_group_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_group_entry TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_group_entry TO writeaccess;

