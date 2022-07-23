--
-- Name: v_mage_filter_set_criteria; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_filter_set_criteria AS
 SELECT tf.filter_set_id,
    tg.filter_criteria_group_id,
    tn.criterion_name,
    tc.criterion_comparison,
    tc.criterion_value,
    tc.criterion_id
   FROM (((public.t_filter_sets tf
     JOIN public.t_filter_set_criteria_groups tg ON ((tf.filter_set_id = tg.filter_set_id)))
     JOIN public.t_filter_set_criteria tc ON ((tg.filter_criteria_group_id = tc.filter_criteria_group_id)))
     JOIN public.t_filter_set_criteria_names tn ON ((tc.criterion_id = tn.criterion_id)));


ALTER TABLE public.v_mage_filter_set_criteria OWNER TO d3l243;

--
-- Name: TABLE v_mage_filter_set_criteria; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_filter_set_criteria TO readaccess;

