--
-- Name: v_param_file_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_detail_report AS
 SELECT pf.param_file_id AS id,
    pf.param_file_name AS name,
    pft.param_file_type AS type,
    pft.param_file_type_id AS type_id,
    pf.param_file_description AS description,
    tool.analysis_tool AS primary_tool,
    pf.date_created AS created,
    pf.date_modified AS modified,
    pf.job_usage_count,
    pf.job_usage_last_year,
    public.combine_paths((tool.param_file_storage_path)::text, (pf.param_file_name)::text) AS file_path,
    pf.valid,
    public.get_param_file_mass_mods_table_code(pf.param_file_id) AS mass_mods,
    public.get_maxquant_mass_mods_list(pf.param_file_id) AS max_quant_mods,
    pf.mod_list AS mod_code_list,
    public.get_param_file_mass_mod_code_list(pf.param_file_id, 1) AS mod_codes_with_symbols
   FROM ((public.t_param_files pf
     JOIN public.t_param_file_types pft ON ((pf.param_file_type_id = pft.param_file_type_id)))
     JOIN public.t_analysis_tool tool ON ((pft.primary_tool_id = tool.analysis_tool_id)));


ALTER TABLE public.v_param_file_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_param_file_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_param_file_detail_report TO writeaccess;

