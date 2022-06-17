--
-- Name: v_nexus_import_proposal_participants; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_nexus_import_proposal_participants AS
 SELECT vw_proposal_participants.project_id,
    vw_proposal_participants.user_id,
    vw_proposal_participants.hanford_id,
    vw_proposal_participants.last_name,
    vw_proposal_participants.first_name,
    vw_proposal_participants.name_fm
   FROM eus.vw_proposal_participants;


ALTER TABLE public.v_nexus_import_proposal_participants OWNER TO d3l243;

--
-- Name: TABLE v_nexus_import_proposal_participants; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_nexus_import_proposal_participants TO readaccess;

