--
-- Name: t_bionet_hosts; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_bionet_hosts (
    host public.citext NOT NULL,
    ip public.citext,
    alias public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_online timestamp without time zone,
    instruments public.citext,
    active smallint DEFAULT 1 NOT NULL,
    tag public.citext,
    comment public.citext
);


ALTER TABLE public.t_bionet_hosts OWNER TO d3l243;

--
-- Name: t_bionet_hosts pk_t_bionet_hosts; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_bionet_hosts
    ADD CONSTRAINT pk_t_bionet_hosts PRIMARY KEY (host);

ALTER TABLE public.t_bionet_hosts CLUSTER ON pk_t_bionet_hosts;

--
-- Name: TABLE t_bionet_hosts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_bionet_hosts TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_bionet_hosts TO writeaccess;

