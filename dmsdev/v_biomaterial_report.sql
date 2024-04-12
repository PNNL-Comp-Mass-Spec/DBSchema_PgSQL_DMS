--
-- Name: v_biomaterial_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_report AS
 SELECT b.biomaterial_name AS name,
    b.source_name AS source,
    b.contact_username AS contact,
    btn.biomaterial_type AS type,
    b.reason,
    b.created,
    b.pi_username AS pi,
    b.comment,
    c.campaign,
    b.biomaterial_id AS id
   FROM ((public.t_biomaterial b
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type_id = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)));


ALTER VIEW public.v_biomaterial_report OWNER TO d3l243;

--
-- Name: VIEW v_biomaterial_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_biomaterial_report IS 'V_Cell_Culture_Report';

--
-- Name: TABLE v_biomaterial_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_report TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_report TO writeaccess;

