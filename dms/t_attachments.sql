--
-- Name: t_attachments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_attachments (
    attachment_id integer NOT NULL,
    attachment_type public.citext NOT NULL,
    attachment_name public.citext NOT NULL,
    attachment_description public.citext,
    owner_prn public.citext,
    active public.citext NOT NULL,
    contents public.citext,
    file_name public.citext NOT NULL,
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.t_attachments OWNER TO d3l243;

--
-- Name: TABLE t_attachments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_attachments TO readaccess;

