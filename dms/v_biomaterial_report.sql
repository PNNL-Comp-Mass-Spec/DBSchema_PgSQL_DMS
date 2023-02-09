--
-- Name: v_biomaterial_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_report AS
 SELECT u.biomaterial_name AS name,
    u.source_name AS source,
    u.contact_username AS contact,
    ctn.biomaterial_type AS type,
    u.reason,
    u.created,
    u.pi_username AS pi,
    u.comment,
    c.campaign,
    u.biomaterial_id AS id
   FROM ((public.t_biomaterial u
     JOIN public.t_biomaterial_type_name ctn ON ((u.biomaterial_type = ctn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((u.campaign_id = c.campaign_id)));


ALTER TABLE public.v_biomaterial_report OWNER TO d3l243;

--
-- Name: VIEW v_biomaterial_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_biomaterial_report IS 'V_Cell_Culture_Report';

--
-- Name: TABLE v_biomaterial_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_report TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_report TO writeaccess;

