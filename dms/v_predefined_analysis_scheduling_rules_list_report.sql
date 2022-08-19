--
-- Name: v_predefined_analysis_scheduling_rules_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_scheduling_rules_list_report AS
 SELECT pasr.rule_id AS id,
    pasr.evaluation_order,
    pasr.instrument_class,
    pasr.instrument_name AS instrument,
    pasr.dataset_name AS dataset,
    pasr.analysis_tool_name AS analysis_tool,
    pasr.priority,
    COALESCE(ajpg.group_name, ''::public.citext) AS processor_group,
    pasr.enabled
   FROM (public.t_predefined_analysis_scheduling_rules pasr
     LEFT JOIN public.t_analysis_job_processor_group ajpg ON ((pasr.processor_group_id = ajpg.group_id)));


ALTER TABLE public.v_predefined_analysis_scheduling_rules_list_report OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_scheduling_rules_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_scheduling_rules_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_predefined_analysis_scheduling_rules_list_report TO writeaccess;

