--
-- Name: t_file_attachment; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_file_attachment (
    attachment_id integer NOT NULL,
    file_name public.citext NOT NULL,
    description public.citext,
    entity_type public.citext NOT NULL,
    entity_id public.citext NOT NULL,
    entity_id_value integer,
    owner_username public.citext NOT NULL,
    file_size_kb public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    archive_folder_path public.citext NOT NULL,
    file_mime_type public.citext,
    active smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_file_attachment OWNER TO d3l243;

--
-- Name: t_file_attachment_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_file_attachment ALTER COLUMN attachment_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_file_attachment_attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_file_attachment pk_t_file_attachment; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_file_attachment
    ADD CONSTRAINT pk_t_file_attachment PRIMARY KEY (attachment_id);

--
-- Name: ix_t_file_attachment_entity_type_active_entity_id_value; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_file_attachment_entity_type_active_entity_id_value ON public.t_file_attachment USING btree (entity_type, active) INCLUDE (entity_id_value);

--
-- Name: ix_t_file_attachment_entity_type_active_include_entity_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_file_attachment_entity_type_active_include_entity_id ON public.t_file_attachment USING btree (entity_type, active) INCLUDE (entity_id);

--
-- Name: TABLE t_file_attachment; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_file_attachment TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_file_attachment TO writeaccess;

