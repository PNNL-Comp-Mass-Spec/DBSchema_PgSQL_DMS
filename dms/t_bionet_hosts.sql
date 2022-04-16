--
-- Name: t_bionet_hosts; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_bionet_hosts (
    host public.citext NOT NULL,
    ip public.citext,
    alias public.citext,
    entered timestamp without time zone,
    last_online timestamp without time zone,
    instruments public.citext,
    active smallint NOT NULL,
    tag public.citext,
    comment public.citext
);


ALTER TABLE public.t_bionet_hosts OWNER TO d3l243;

--
-- Name: TABLE t_bionet_hosts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_bionet_hosts TO readaccess;

