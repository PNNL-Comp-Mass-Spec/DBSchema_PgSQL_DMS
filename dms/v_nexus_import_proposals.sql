--
-- Name: v_nexus_import_proposals; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_nexus_import_proposals AS
 SELECT project_id,
    title,
    proposal_type,
    proposal_type_display,
    actual_start_date,
    actual_end_date,
    project_uuid,
    row_number() OVER (PARTITION BY project_id ORDER BY actual_start_date DESC, actual_end_date DESC) AS id_rank
   FROM eus.vw_proposals;


ALTER VIEW public.v_nexus_import_proposals OWNER TO d3l243;

--
-- Name: TABLE v_nexus_import_proposals; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_nexus_import_proposals TO readaccess;
GRANT SELECT ON TABLE public.v_nexus_import_proposals TO writeaccess;

