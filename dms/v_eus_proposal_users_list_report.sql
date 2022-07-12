--
-- Name: v_eus_proposal_users_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposal_users_list_report AS
 SELECT pu.person_id AS eus_person_id,
    pu.of_dms_interest AS dms_interest,
    u.name_fm AS name,
    ss.eus_site_status AS site_status,
    pu.proposal_id AS eus_proposal_id,
    u.first_name,
    u.last_name
   FROM ((public.t_eus_proposal_users pu
     JOIN public.t_eus_users u ON ((pu.person_id = u.person_id)))
     JOIN public.t_eus_site_status ss ON ((u.site_status = ss.eus_site_status_id)))
  WHERE (pu.state_id <> 5);


ALTER TABLE public.v_eus_proposal_users_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposal_users_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposal_users_list_report TO readaccess;

