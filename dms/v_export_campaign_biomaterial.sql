--
-- Name: v_export_campaign_biomaterial; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_export_campaign_biomaterial AS
 SELECT c.campaign,
    b.biomaterial_name AS biomaterial,
    b.biomaterial_id
   FROM (public.t_campaign c
     JOIN public.t_biomaterial b ON ((c.campaign_id = b.campaign_id)));


ALTER TABLE public.v_export_campaign_biomaterial OWNER TO d3l243;

--
-- Name: TABLE v_export_campaign_biomaterial; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_export_campaign_biomaterial TO readaccess;

