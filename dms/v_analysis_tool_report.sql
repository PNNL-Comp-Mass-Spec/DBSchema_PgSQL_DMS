--
-- Name: v_analysis_tool_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_tool_report AS
 SELECT tool.analysis_tool AS name,
    tool.analysis_tool_id AS id,
    tool.result_type,
    tool.param_file_storage_path AS param_file_storage_client,
    tool.param_file_storage_path_local AS param_file_storage_server,
    public.get_analysis_tool_allowed_instrument_class_list(tool.analysis_tool_id) AS allowed_inst_classes,
    tool.default_settings_file_name AS default_settings_file,
    tool.active,
    tool.org_db_required AS org_db_req,
    tool.extraction_required AS extract_req,
    public.get_analysis_tool_allowed_dataset_type_list(tool.analysis_tool_id) AS allowed_ds_types
   FROM public.t_analysis_tool tool
  WHERE (tool.analysis_tool_id > 0);


ALTER TABLE public.v_analysis_tool_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_tool_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_tool_report TO readaccess;

