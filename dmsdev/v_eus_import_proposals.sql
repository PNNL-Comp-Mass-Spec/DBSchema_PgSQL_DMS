--
-- Name: v_eus_import_proposals; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_import_proposals AS
 SELECT project_id AS proposal_id,
    title,
    proposal_type_display AS proposal_type,
    actual_end_date,
    actual_start_date
   FROM eus.vw_proposals;


ALTER VIEW public.v_eus_import_proposals OWNER TO d3l243;

--
-- Name: TABLE v_eus_import_proposals; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_import_proposals TO readaccess;
GRANT SELECT ON TABLE public.v_eus_import_proposals TO writeaccess;

