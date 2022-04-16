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
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.t_prep_file_storage OWNER TO d3l243;

--
-- Name: TABLE t_prep_file_storage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_file_storage TO readaccess;

