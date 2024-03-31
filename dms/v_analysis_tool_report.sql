--
-- Name: v_analysis_tool_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_tool_report AS
 SELECT analysis_tool AS name,
    analysis_tool_id AS id,
    result_type,
    param_file_storage_path AS param_file_storage_client,
    param_file_storage_path_local AS param_file_storage_server,
    (public.get_analysis_tool_allowed_instrument_class_list(analysis_tool_id))::public.citext AS allowed_inst_classes,
    default_settings_file_name AS default_settings_file,
    active,
    org_db_required AS org_db_req,
    extraction_required AS extract_req,
    (public.get_analysis_tool_allowed_dataset_type_list(analysis_tool_id))::public.citext AS allowed_ds_types
   FROM public.t_analysis_tool tool
  WHERE (analysis_tool_id > 0);


ALTER VIEW public.v_analysis_tool_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_tool_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_tool_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_tool_report TO writeaccess;

