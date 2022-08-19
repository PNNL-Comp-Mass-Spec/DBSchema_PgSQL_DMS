--
-- Name: t_prep_file_storage; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_prep_file_storage (
    storage_id integer NOT NULL,
    purpose public.citext NOT NULL,
    path_local_root public.citext NOT NULL,
    path_shared_root public.citext,
    path_web_root public.citext,
    path_archive_root public.citext,
    state public.citext NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_prep_file_storage OWNER TO d3l243;

--
-- Name: t_prep_file_storage_storage_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_prep_file_storage ALTER COLUMN storage_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_prep_file_storage_storage_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_prep_file_storage pk_t_prep_file_storage; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_file_storage
    ADD CONSTRAINT pk_t_prep_file_storage PRIMARY KEY (storage_id);

--
-- Name: TABLE t_prep_file_storage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_file_storage TO readaccess;
GRANT SELECT ON TABLE public.t_prep_file_storage TO writeaccess;

