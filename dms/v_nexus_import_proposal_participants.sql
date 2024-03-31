--
-- Name: v_nexus_import_proposal_participants; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_nexus_import_proposal_participants AS
 SELECT project_id,
    user_id,
    hanford_id,
    last_name,
    first_name,
    name_fm
   FROM eus.vw_proposal_participants;


ALTER VIEW public.v_nexus_import_proposal_participants OWNER TO d3l243;

--
-- Name: TABLE v_nexus_import_proposal_participants; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_nexus_import_proposal_participants TO readaccess;
GRANT SELECT ON TABLE public.v_nexus_import_proposal_participants TO writeaccess;

