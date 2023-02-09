--
-- Name: t_attachments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_attachments (
    attachment_id integer NOT NULL,
    attachment_type public.citext NOT NULL,
    attachment_name public.citext NOT NULL,
    attachment_description public.citext,
    owner_username public.citext,
    active public.citext DEFAULT 'Y'::public.citext NOT NULL,
    contents public.citext,
    file_name public.citext NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_attachments OWNER TO d3l243;

--
-- Name: t_attachments_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_attachments ALTER COLUMN attachment_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_attachments_attachment_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_attachments pk_t_attachments; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_attachments
    ADD CONSTRAINT pk_t_attachments PRIMARY KEY (attachment_id);

--
-- Name: ix_t_attachments; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_attachments ON public.t_attachments USING btree (attachment_name);

--
-- Name: TABLE t_attachments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_attachments TO readaccess;
GRANT SELECT ON TABLE public.t_attachments TO writeaccess;

