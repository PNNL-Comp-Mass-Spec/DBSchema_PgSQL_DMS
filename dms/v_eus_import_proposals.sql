--
-- Name: v_eus_import_proposals; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_import_proposals AS
 SELECT vw_proposals.project_id AS proposal_id,
    vw_proposals.title,
    vw_proposals.proposal_type_display AS proposal_type,
    vw_proposals.actual_end_date,
    vw_proposals.actual_start_date
   FROM eus.vw_proposals;


ALTER TABLE public.v_eus_import_proposals OWNER TO d3l243;

--
-- Name: TABLE v_eus_import_proposals; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_import_proposals TO readaccess;

