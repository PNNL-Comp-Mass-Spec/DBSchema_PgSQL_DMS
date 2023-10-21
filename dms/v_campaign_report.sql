--
-- Name: v_campaign_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_report AS
 SELECT t_campaign.campaign,
    t_campaign.project,
    (public.get_campaign_role_person(t_campaign.campaign_id, 'Project Mgr'::text))::public.citext AS project_mgr,
    (public.get_campaign_role_person(t_campaign.campaign_id, 'PI'::text))::public.citext AS pi,
    t_campaign.comment,
    t_campaign.created,
    t_campaign.state
   FROM public.t_campaign;


ALTER TABLE public.v_campaign_report OWNER TO d3l243;

--
-- Name: TABLE v_campaign_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_report TO readaccess;
GRANT SELECT ON TABLE public.v_campaign_report TO writeaccess;

