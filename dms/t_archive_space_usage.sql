--
-- Name: t_archive_space_usage; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_archive_space_usage (
    entry_id integer NOT NULL,
    sampling_date timestamp without time zone NOT NULL,
    data_mb bigint NOT NULL,
    files integer,
    folders integer,
    comment public.citext,
    entered_by public.citext
);


ALTER TABLE public.t_archive_space_usage OWNER TO d3l243;

--
-- Name: TABLE t_archive_space_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_archive_space_usage TO readaccess;

