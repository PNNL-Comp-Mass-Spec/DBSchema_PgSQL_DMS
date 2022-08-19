--
-- Name: v_nexus_import_proposals; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_nexus_import_proposals AS
 SELECT vw_proposals.project_id,
    vw_proposals.title,
    vw_proposals.proposal_type,
    vw_proposals.proposal_type_display,
    vw_proposals.actual_start_date,
    vw_proposals.actual_end_date,
    vw_proposals.project_uuid,
    row_number() OVER (PARTITION BY vw_proposals.project_id ORDER BY vw_proposals.actual_start_date, vw_proposals.actual_end_date) AS id_rank
   FROM eus.vw_proposals;


ALTER TABLE public.v_nexus_import_proposals OWNER TO d3l243;

--
-- Name: TABLE v_nexus_import_proposals; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_nexus_import_proposals TO readaccess;
GRANT SELECT ON TABLE public.v_nexus_import_proposals TO writeaccess;

