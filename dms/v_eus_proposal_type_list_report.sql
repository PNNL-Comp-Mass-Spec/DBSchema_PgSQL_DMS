--
-- Name: v_eus_proposal_type_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposal_type_list_report AS
 SELECT ept.proposal_type_name AS proposal_type,
    ept.abbreviation,
    ept.proposal_type AS proposal_type_nexus,
    count(eup.proposal_id) AS eus_proposals
   FROM (public.t_eus_proposal_type ept
     LEFT JOIN public.t_eus_proposals eup ON ((ept.proposal_type_name OPERATOR(public.=) eup.proposal_type)))
  GROUP BY ept.proposal_type_name, ept.abbreviation, ept.proposal_type;


ALTER VIEW public.v_eus_proposal_type_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposal_type_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposal_type_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_eus_proposal_type_list_report TO writeaccess;

