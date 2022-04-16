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
    owner_prn public.citext NOT NULL,
    file_size_bytes public.citext,
    created timestamp without time zone NOT NULL,
    last_affected timestamp without time zone NOT NULL,
    archive_folder_path public.citext NOT NULL,
    file_mime_type public.citext,
    active smallint NOT NULL
);


ALTER TABLE public.t_file_attachment OWNER TO d3l243;

--
-- Name: TABLE t_file_attachment; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_file_attachment TO readaccess;

