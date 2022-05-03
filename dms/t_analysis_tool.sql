--
-- Name: t_analysis_tool; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_tool (
    analysis_tool_id integer NOT NULL,
    analysis_tool public.citext NOT NULL,
    tool_base_name public.citext NOT NULL,
    param_file_type_id integer,
    param_file_storage_path public.citext,
    param_file_storage_path_local public.citext,
    default_settings_file_name public.citext,
    result_type public.citext,
    auto_scan_folder_flag character(3),
    active smallint NOT NULL,
    search_engine_input_file_formats public.citext,
    org_db_required smallint NOT NULL,
    extraction_required character(1) NOT NULL,
    description public.citext,
    use_special_proc_waiting smallint NOT NULL,
    settings_file_required smallint NOT NULL,
    param_file_required smallint NOT NULL
);


ALTER TABLE public.t_analysis_tool OWNER TO d3l243;

--
-- Name: t_analysis_tool pk_t_analysis_tool; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_tool
    ADD CONSTRAINT pk_t_analysis_tool PRIMARY KEY (analysis_tool_id);

--
-- Name: TABLE t_analysis_tool; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_tool TO readaccess;

