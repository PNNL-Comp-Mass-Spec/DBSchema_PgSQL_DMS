--
-- Name: v_campaign_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_report AS
 SELECT campaign,
    project,
    (public.get_campaign_role_person(campaign_id, 'Project Mgr'::text))::public.citext AS project_mgr,
    (public.get_campaign_role_person(campaign_id, 'PI'::text))::public.citext AS pi,
    comment,
    created,
    state
   FROM public.t_campaign;


ALTER VIEW public.v_campaign_report OWNER TO d3l243;

--
-- Name: TABLE v_campaign_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_report TO readaccess;
GRANT SELECT ON TABLE public.v_campaign_report TO writeaccess;

