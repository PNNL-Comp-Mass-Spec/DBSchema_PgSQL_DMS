--
-- Name: v_biomaterial_report_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_report_ex AS
 SELECT r.name,
    r.source,
    r.contact,
    r.type,
    r.reason,
    r.pi,
    r.comment,
    r.campaign,
    count(t_experiment_biomaterial.biomaterial_id) AS exp_count
   FROM (public.v_biomaterial_report r
     JOIN public.t_experiment_biomaterial ON ((r."#id" = t_experiment_biomaterial.biomaterial_id)))
  GROUP BY r.name, r.source, r.pi, r.type, r.reason, r.comment, r.campaign, r.contact;


ALTER TABLE public.v_biomaterial_report_ex OWNER TO d3l243;

--
-- Name: VIEW v_biomaterial_report_ex; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_biomaterial_report_ex IS 'V_Cell_Culture_Report_Ex';

--
-- Name: TABLE v_biomaterial_report_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_report_ex TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_report_ex TO writeaccess;

