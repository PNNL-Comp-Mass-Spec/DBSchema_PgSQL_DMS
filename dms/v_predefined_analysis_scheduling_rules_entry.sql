--
-- Name: v_predefined_analysis_scheduling_rules_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_scheduling_rules_entry AS
 SELECT pasr.evaluation_order,
    pasr.instrument_class,
    pasr.instrument_name,
    pasr.dataset_name,
    pasr.analysis_tool_name,
    pasr.priority,
    COALESCE(ajpg.group_name, ''::public.citext) AS processor_group,
    pasr.enabled,
    pasr.created,
    pasr.rule_id AS id
   FROM (public.t_predefined_analysis_scheduling_rules pasr
     LEFT JOIN public.t_analysis_job_processor_group ajpg ON ((pasr.processor_group_id = ajpg.group_id)));


ALTER TABLE public.v_predefined_analysis_scheduling_rules_entry OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_scheduling_rules_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_scheduling_rules_entry TO readaccess;

