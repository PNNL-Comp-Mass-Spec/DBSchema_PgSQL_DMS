--
-- Name: t_settings_files; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_settings_files (
    settings_file_id integer NOT NULL,
    analysis_tool public.citext NOT NULL,
    file_name public.citext NOT NULL,
    description public.citext DEFAULT ''::public.citext,
    active smallint DEFAULT 1,
    contents xml,
    job_usage_count integer DEFAULT 0,
    hms_auto_supersede public.citext,
    msgfplus_auto_centroid public.citext,
    comment public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    job_usage_last_year integer,
    CONSTRAINT ck_t_settings_files_settings_file_name_white_space CHECK ((public.has_whitespace_chars((file_name)::text, 0) = false))
);


ALTER TABLE public.t_settings_files OWNER TO d3l243;

--
-- Name: t_settings_files_settings_file_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_settings_files ALTER COLUMN settings_file_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_settings_files_settings_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_settings_files pk_t_settings_files; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_settings_files
    ADD CONSTRAINT pk_t_settings_files PRIMARY KEY (settings_file_id);

--
-- Name: ix_t_settings_files_analysis_tool_file_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_settings_files_analysis_tool_file_name ON public.t_settings_files USING btree (analysis_tool, file_name);

--
-- Name: ix_t_settings_files_file_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_settings_files_file_name ON public.t_settings_files USING btree (file_name);

--
-- Name: t_settings_files fk_t_settings_files_t_analysis_tool; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_settings_files
    ADD CONSTRAINT fk_t_settings_files_t_analysis_tool FOREIGN KEY (analysis_tool) REFERENCES public.t_analysis_tool(analysis_tool);

--
-- Name: TABLE t_settings_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_settings_files TO readaccess;

