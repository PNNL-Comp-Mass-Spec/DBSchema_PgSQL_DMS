--
-- Name: t_archive_space_usage; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_archive_space_usage (
    entry_id integer NOT NULL,
    sampling_date timestamp without time zone NOT NULL,
    data_mb bigint NOT NULL,
    files integer,
    folders integer,
    comment public.citext DEFAULT ''::public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_archive_space_usage OWNER TO d3l243;

--
-- Name: t_archive_space_usage_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_archive_space_usage ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_archive_space_usage_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_archive_space_usage pk_t_archive_space_usage; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_archive_space_usage
    ADD CONSTRAINT pk_t_archive_space_usage PRIMARY KEY (entry_id);

--
-- Name: TABLE t_archive_space_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_archive_space_usage TO readaccess;

