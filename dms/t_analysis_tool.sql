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
    active smallint DEFAULT 1 NOT NULL,
    search_engine_input_file_formats public.citext,
    org_db_required smallint DEFAULT 0 NOT NULL,
    extraction_required character(1) DEFAULT 'N'::bpchar NOT NULL,
    description public.citext,
    use_special_proc_waiting smallint DEFAULT 0 NOT NULL,
    settings_file_required smallint DEFAULT 1 NOT NULL,
    param_file_required smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_analysis_tool OWNER TO d3l243;

--
-- Name: t_analysis_tool pk_t_analysis_tool; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_tool
    ADD CONSTRAINT pk_t_analysis_tool PRIMARY KEY (analysis_tool_id);

--
-- Name: ix_t_analysis_tool_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_analysis_tool_name ON public.t_analysis_tool USING btree (analysis_tool);

--
-- Name: t_analysis_tool fk_t_analysis_tool_t_param_file_types; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_tool
    ADD CONSTRAINT fk_t_analysis_tool_t_param_file_types FOREIGN KEY (param_file_type_id) REFERENCES public.t_param_file_types(param_file_type_id);

--
-- Name: TABLE t_analysis_tool; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_tool TO readaccess;
GRANT SELECT ON TABLE public.t_analysis_tool TO writeaccess;

