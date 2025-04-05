--
-- Name: t_storage_path_hosts; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_storage_path_hosts (
    machine_name public.citext NOT NULL,
    host_name public.citext NOT NULL,
    dns_suffix public.citext NOT NULL,
    url_prefix public.citext
);


ALTER TABLE public.t_storage_path_hosts OWNER TO d3l243;

--
-- Name: t_storage_path_hosts pk_t_storage_path_hosts; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_storage_path_hosts
    ADD CONSTRAINT pk_t_storage_path_hosts PRIMARY KEY (machine_name);

ALTER TABLE public.t_storage_path_hosts CLUSTER ON pk_t_storage_path_hosts;

--
-- Name: TABLE t_storage_path_hosts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_storage_path_hosts TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_storage_path_hosts TO writeaccess;

