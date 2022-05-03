--
-- Name: t_archive_path; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_archive_path (
    archive_path_id integer NOT NULL,
    instrument_id integer NOT NULL,
    archive_path public.citext NOT NULL,
    note public.citext,
    archive_path_function public.citext NOT NULL,
    archive_server_name public.citext,
    network_share_path public.citext,
    archive_url public.citext,
    created timestamp without time zone
);


ALTER TABLE public.t_archive_path OWNER TO d3l243;

--
-- Name: t_archive_path_archive_path_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_archive_path ALTER COLUMN archive_path_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_archive_path_archive_path_id_seq
    START WITH 110
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_archive_path pk_t_archive_path; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_archive_path
    ADD CONSTRAINT pk_t_archive_path PRIMARY KEY (archive_path_id);

--
-- Name: TABLE t_archive_path; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_archive_path TO readaccess;

