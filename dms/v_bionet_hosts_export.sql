--
-- Name: v_bionet_hosts_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_bionet_hosts_export AS
 SELECT t_bionet_hosts.host,
    t_bionet_hosts.ip,
    t_bionet_hosts.alias,
    t_bionet_hosts.entered,
    t_bionet_hosts.last_online,
    t_bionet_hosts.comment AS instruments,
    t_bionet_hosts.tag,
    t_bionet_hosts.active
   FROM public.t_bionet_hosts;


ALTER VIEW public.v_bionet_hosts_export OWNER TO d3l243;

--
-- Name: TABLE v_bionet_hosts_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_bionet_hosts_export TO readaccess;
GRANT SELECT ON TABLE public.v_bionet_hosts_export TO writeaccess;

