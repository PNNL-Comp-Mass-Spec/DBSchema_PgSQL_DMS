--
-- Name: v_eus_users_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_users_list_report AS
 SELECT u.person_id AS id,
    u.name_fm AS name,
    ss.eus_site_status AS site_status,
    public.get_eus_users_proposal_list(u.person_id) AS proposals,
    u.hid AS hanford_id,
    u.valid AS valid_eus_id,
    u.last_affected
   FROM (public.t_eus_users u
     JOIN public.t_eus_site_status ss ON ((u.site_status = ss.eus_site_status_id)));


ALTER TABLE public.v_eus_users_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_users_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_users_list_report TO readaccess;

