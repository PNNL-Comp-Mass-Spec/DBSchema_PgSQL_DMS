--
-- Name: v_campaign_biomaterial_tracking; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_biomaterial_tracking AS
 SELECT t_biomaterial.biomaterial_name AS cell_culture,
    t_biomaterial.reason,
    t_biomaterial.created,
    t_campaign.campaign AS "#Campaign"
   FROM (public.t_campaign
     JOIN public.t_biomaterial ON ((t_campaign.campaign_id = t_biomaterial.campaign_id)));


ALTER TABLE public.v_campaign_biomaterial_tracking OWNER TO d3l243;

--
-- Name: TABLE v_campaign_biomaterial_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_biomaterial_tracking TO readaccess;

