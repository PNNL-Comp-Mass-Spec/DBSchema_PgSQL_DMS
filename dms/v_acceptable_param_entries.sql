--
-- Name: v_acceptable_param_entries; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_acceptable_param_entries AS
 SELECT paramentries.parameter_name,
    paramentries.canonical_name,
    paramentries.parameter_category,
    paramentries.default_value,
    entrytypes.param_entry_type_name,
    entrytypes.formatting_string,
    paramentries.picker_items_list,
    paramentries.output_order,
    tool.analysis_tool AS analysis_job_toolname,
    tool.param_file_type_id,
    paramentries.first_applicable_version,
    paramentries.last_applicable_version,
    entrytypes.param_entry_type_id,
    paramentries.display_name
   FROM ((public.t_acceptable_param_entries paramentries
     JOIN public.t_acceptable_param_entry_types entrytypes ON ((paramentries.param_entry_type_id = entrytypes.param_entry_type_id)))
     JOIN public.t_analysis_tool tool ON ((paramentries.analysis_tool_id = tool.analysis_tool_id)));


ALTER TABLE public.v_acceptable_param_entries OWNER TO d3l243;

--
-- Name: TABLE v_acceptable_param_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_acceptable_param_entries TO readaccess;
GRANT SELECT ON TABLE public.v_acceptable_param_entries TO writeaccess;

