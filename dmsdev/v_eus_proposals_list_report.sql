--
-- Name: v_eus_proposals_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposals_list_report AS
 SELECT DISTINCT eup.proposal_id AS id,
    s.state_name AS state,
    (public.get_proposal_eus_users_list((eup.proposal_id)::text, 'N'::text, 125))::public.citext AS users,
    eup.title,
    eup.import_date,
    eup.proposal_start_date AS start_date,
    eup.proposal_end_date AS end_date,
    ept.proposal_type_name AS proposal_type,
    ept.abbreviation,
    eup.numeric_id,
    eup.proposal_id_auto_supersede AS superseded_by
   FROM ((public.t_eus_proposals eup
     JOIN public.t_eus_proposal_state_name s ON ((eup.state_id = s.state_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)));


ALTER VIEW public.v_eus_proposals_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposals_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposals_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_eus_proposals_list_report TO writeaccess;

