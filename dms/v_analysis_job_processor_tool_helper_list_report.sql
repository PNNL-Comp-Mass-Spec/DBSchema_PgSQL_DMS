--
-- Name: v_analysis_job_processor_tool_helper_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_tool_helper_list_report AS
 SELECT tool.analysis_tool AS name,
    tool.result_type,
    (public.get_analysis_tool_allowed_instrument_class_list(tool.analysis_tool_id))::public.citext AS allowed_inst_classes,
    tool.org_db_required AS org_db_req,
    tool.extraction_required AS extract_req,
    (public.get_analysis_tool_allowed_dataset_type_list(tool.analysis_tool_id))::public.citext AS allowed_ds_types
   FROM public.t_analysis_tool tool
  WHERE ((tool.analysis_tool_id > 0) AND (tool.active = 1));


ALTER TABLE public.v_analysis_job_processor_tool_helper_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_tool_helper_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_tool_helper_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processor_tool_helper_list_report TO writeaccess;

