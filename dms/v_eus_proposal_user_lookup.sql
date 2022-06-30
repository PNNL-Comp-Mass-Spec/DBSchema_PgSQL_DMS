--
-- Name: v_eus_proposal_user_lookup; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposal_user_lookup AS
 SELECT eu.person_id AS eus_user_id,
    eu.name_fm AS eus_user_name,
    p.proposal_id,
    p.proposal_start_date,
    p.proposal_end_date,
    u.username AS user_prn,
    eu.valid AS valid_eus_id
   FROM (((public.t_eus_proposal_users pu
     JOIN public.t_eus_users eu ON ((pu.person_id = eu.person_id)))
     JOIN public.t_eus_proposals p ON ((pu.proposal_id OPERATOR(public.=) p.proposal_id)))
     LEFT JOIN public.t_users u ON ((eu.hid OPERATOR(public.=) u.hid)));


ALTER TABLE public.v_eus_proposal_user_lookup OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposal_user_lookup; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposal_user_lookup TO readaccess;

