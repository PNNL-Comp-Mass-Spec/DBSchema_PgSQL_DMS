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
    job_usage_last_year integer DEFAULT 0,
    CONSTRAINT ck_t_settings_files_settings_file_name_whitespace CHECK ((public.has_whitespace_chars((file_name)::text, false) = false))
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

ALTER TABLE public.t_settings_files CLUSTER ON pk_t_settings_files;

--
-- Name: ix_t_settings_files_analysis_tool_file_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_settings_files_analysis_tool_file_name ON public.t_settings_files USING btree (analysis_tool, file_name);

--
-- Name: ix_t_settings_files_file_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_settings_files_file_name ON public.t_settings_files USING btree (file_name);

--
-- Name: t_settings_files trig_t_settings_files_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_settings_files_after_delete AFTER DELETE ON public.t_settings_files REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_settings_files_after_delete();

--
-- Name: t_settings_files trig_t_settings_files_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_settings_files_after_insert AFTER INSERT ON public.t_settings_files REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_settings_files_after_insert();

--
-- Name: t_settings_files trig_t_settings_files_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_settings_files_after_update AFTER UPDATE ON public.t_settings_files FOR EACH ROW WHEN ((((old.hms_auto_supersede)::text IS DISTINCT FROM (new.hms_auto_supersede)::text) OR ((old.msgfplus_auto_centroid)::text IS DISTINCT FROM (new.msgfplus_auto_centroid)::text) OR (old.analysis_tool OPERATOR(public.<>) new.analysis_tool) OR (old.file_name OPERATOR(public.<>) new.file_name) OR ((old.contents)::text IS DISTINCT FROM (new.contents)::text))) EXECUTE FUNCTION public.trigfn_t_settings_files_after_update();

--
-- Name: t_settings_files fk_t_settings_files_t_analysis_tool; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_settings_files
    ADD CONSTRAINT fk_t_settings_files_t_analysis_tool FOREIGN KEY (analysis_tool) REFERENCES public.t_analysis_tool(analysis_tool);

--
-- Name: TABLE t_settings_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_settings_files TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_settings_files TO writeaccess;

