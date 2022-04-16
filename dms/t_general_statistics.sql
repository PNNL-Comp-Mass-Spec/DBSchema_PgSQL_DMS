--
-- Name: t_general_statistics; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_general_statistics (
    entry_id integer NOT NULL,
    category public.citext NOT NULL,
    label public.citext NOT NULL,
    value public.citext,
    last_affected timestamp without time zone
);


ALTER TABLE public.t_general_statistics OWNER TO d3l243;

--
-- Name: TABLE t_general_statistics; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_general_statistics TO readaccess;

