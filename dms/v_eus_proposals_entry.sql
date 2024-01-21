--
-- Name: v_eus_proposals_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposals_entry AS
 SELECT p.proposal_id AS id,
    p.state_id AS state,
    p.title,
    p.import_date,
    p.proposal_type,
    p.proposal_id_auto_supersede AS superseded_by,
    public.get_proposal_eus_users_list((p.proposal_id)::text, 'I'::text, 1000) AS eus_users
   FROM public.t_eus_proposals p;


ALTER VIEW public.v_eus_proposals_entry OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposals_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposals_entry TO readaccess;
GRANT SELECT ON TABLE public.v_eus_proposals_entry TO writeaccess;

