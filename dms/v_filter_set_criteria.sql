--
-- Name: v_filter_set_criteria; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_set_criteria AS
 SELECT fs.filter_set_id,
    fs.filter_set_name,
    fs.filter_set_description,
    fsc.filter_criteria_group_id,
    fsc.filter_set_criteria_id,
    fsc.criterion_id,
    fscn.criterion_name,
    fsc.criterion_comparison,
    fsc.criterion_value
   FROM (((public.t_filter_sets fs
     JOIN public.t_filter_set_criteria_groups fscg ON ((fs.filter_set_id = fscg.filter_set_id)))
     JOIN public.t_filter_set_criteria fsc ON ((fscg.filter_criteria_group_id = fsc.filter_criteria_group_id)))
     JOIN public.t_filter_set_criteria_names fscn ON ((fsc.criterion_id = fscn.criterion_id)));


ALTER TABLE public.v_filter_set_criteria OWNER TO d3l243;

--
-- Name: TABLE v_filter_set_criteria; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_set_criteria TO readaccess;
GRANT SELECT ON TABLE public.v_filter_set_criteria TO writeaccess;

