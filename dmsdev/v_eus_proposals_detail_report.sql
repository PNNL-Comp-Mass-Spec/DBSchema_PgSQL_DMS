--
-- Name: v_eus_proposals_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposals_detail_report AS
 SELECT eup.proposal_id AS id,
    s.state_name AS state,
    eup.title,
    eup.proposal_type,
    ept.proposal_type_name,
    ept.abbreviation,
    eup.proposal_start_date,
    eup.proposal_end_date,
    eup.import_date,
    eup.last_affected,
    eup.proposal_id_auto_supersede AS superseded_by,
    public.get_proposal_eus_users_list((eup.proposal_id)::text, 'V'::text, 1000) AS eus_users
   FROM ((public.t_eus_proposals eup
     JOIN public.t_eus_proposal_state_name s ON ((eup.state_id = s.state_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)));


ALTER VIEW public.v_eus_proposals_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposals_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposals_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_eus_proposals_detail_report TO writeaccess;

