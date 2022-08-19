--
-- Name: v_eus_import_proposal_participants; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_import_proposal_participants AS
 SELECT vw_proposal_participants.project_id AS proposal_id,
    vw_proposal_participants.user_id AS person_id,
    vw_proposal_participants.hanford_id,
    vw_proposal_participants.last_name,
    vw_proposal_participants.first_name,
    vw_proposal_participants.name_fm,
    (((vw_proposal_participants.last_name)::text || ', '::text) || (vw_proposal_participants.first_name)::text) AS name_fm_computed
   FROM eus.vw_proposal_participants;


ALTER TABLE public.v_eus_import_proposal_participants OWNER TO d3l243;

--
-- Name: TABLE v_eus_import_proposal_participants; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_import_proposal_participants TO readaccess;
GRANT SELECT ON TABLE public.v_eus_import_proposal_participants TO writeaccess;

