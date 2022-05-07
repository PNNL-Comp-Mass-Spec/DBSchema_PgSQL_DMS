--
-- Name: t_settings_files_xml_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_settings_files_xml_history (
    event_id integer NOT NULL,
    event_action public.citext NOT NULL,
    id integer NOT NULL,
    analysis_tool public.citext NOT NULL,
    file_name public.citext NOT NULL,
    description public.citext,
    contents xml,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_settings_files_xml_history OWNER TO d3l243;

--
-- Name: t_settings_files_xml_history_event_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_settings_files_xml_history ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_settings_files_xml_history_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_settings_files_xml_history pk_t_settings_files_xml_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_settings_files_xml_history
    ADD CONSTRAINT pk_t_settings_files_xml_history PRIMARY KEY (event_id);

--
-- Name: ix_t_settings_files_xml_history_file_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_settings_files_xml_history_file_name ON public.t_settings_files_xml_history USING btree (file_name);

--
-- Name: ix_t_settings_files_xml_history_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_settings_files_xml_history_id ON public.t_settings_files_xml_history USING btree (id);

--
-- Name: TABLE t_settings_files_xml_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_settings_files_xml_history TO readaccess;

