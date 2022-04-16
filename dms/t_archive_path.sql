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
-- Name: TABLE t_archive_path; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_archive_path TO readaccess;

