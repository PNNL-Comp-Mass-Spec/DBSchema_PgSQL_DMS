--
-- Name: v_eus_project_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_project_picklist AS
 SELECT t_eus_proposal_state_name.state_id AS id,
    t_eus_proposal_state_name.state_name,
    (((((((t_eus_proposal_state_name.state_id)::public.citext)::text || ' - '::text))::public.citext)::text || (t_eus_proposal_state_name.state_name)::text))::public.citext AS id_with_name
   FROM public.t_eus_proposal_state_name;


ALTER VIEW public.v_eus_project_picklist OWNER TO d3l243;

--
-- Name: TABLE v_eus_project_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_project_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_eus_project_picklist TO writeaccess;

