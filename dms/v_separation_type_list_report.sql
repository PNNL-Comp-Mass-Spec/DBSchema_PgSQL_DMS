--
-- Name: v_separation_type_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_separation_type_list_report AS
 SELECT ss.separation_type,
    ss.separation_group,
    ss.comment AS separation_type_comment,
    samptype.name AS sample_type,
    u.usage_last12months AS usage_last_12_months,
    u.usage_all_years AS dataset_usage_all_years,
    u.most_recent_use,
    ss.active,
    ss.separation_type_id AS id,
    ss.created
   FROM ((public.t_secondary_sep ss
     JOIN public.t_secondary_sep_sample_type samptype ON ((ss.sample_type_id = samptype.sample_type_id)))
     LEFT JOIN public.t_secondary_sep_usage u ON ((u.separation_type_id = ss.separation_type_id)));


ALTER TABLE public.v_separation_type_list_report OWNER TO d3l243;

--
-- Name: TABLE v_separation_type_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_separation_type_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_separation_type_list_report TO writeaccess;

