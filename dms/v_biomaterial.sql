--
-- Name: v_biomaterial; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial AS
 SELECT b.biomaterial_id AS id,
    b.biomaterial_name AS name,
    btn.biomaterial_type AS type,
    b.reason,
    b.created,
    b.comment,
    c.campaign
   FROM ((public.t_biomaterial b
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)));


ALTER TABLE public.v_biomaterial OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial TO readaccess;

