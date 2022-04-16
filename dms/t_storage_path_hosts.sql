--
-- Name: t_storage_path_hosts; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_storage_path_hosts (
    sp_machine_name public.citext NOT NULL,
    host_name public.citext NOT NULL,
    dns_suffix public.citext NOT NULL,
    url_prefix public.citext
);


ALTER TABLE public.t_storage_path_hosts OWNER TO d3l243;

--
-- Name: TABLE t_storage_path_hosts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_storage_path_hosts TO readaccess;

