--
-- Name: v_filter_sets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_sets AS
 SELECT fst.filter_type_id,
    fst.filter_type_name,
    fs.filter_set_id,
    fs.filter_set_name,
    fs.filter_set_description,
    fsc.filter_criteria_group_id,
    fscn.criterion_id,
    fscn.criterion_name,
    fsc.filter_set_criteria_id,
    fsc.criterion_comparison,
    fsc.criterion_value
   FROM (((public.t_filter_set_types fst
     JOIN public.t_filter_sets fs ON ((fst.filter_type_id = fs.filter_type_id)))
     JOIN public.t_filter_set_criteria_groups fscg ON ((fs.filter_set_id = fscg.filter_set_id)))
     JOIN (public.t_filter_set_criteria fsc
     JOIN public.t_filter_set_criteria_names fscn ON ((fsc.criterion_id = fscn.criterion_id))) ON ((fscg.filter_criteria_group_id = fsc.filter_criteria_group_id)));


ALTER TABLE public.v_filter_sets OWNER TO d3l243;

--
-- Name: TABLE v_filter_sets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_sets TO readaccess;
GRANT SELECT ON TABLE public.v_filter_sets TO writeaccess;

