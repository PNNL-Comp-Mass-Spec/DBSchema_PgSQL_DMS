--
-- Name: v_bionet_hosts_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_bionet_hosts_export AS
 SELECT host,
    ip,
    alias,
    entered,
    last_online,
    comment AS instruments,
    tag,
    active
   FROM public.t_bionet_hosts;


ALTER VIEW public.v_bionet_hosts_export OWNER TO d3l243;

--
-- Name: TABLE v_bionet_hosts_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_bionet_hosts_export TO readaccess;
GRANT SELECT ON TABLE public.v_bionet_hosts_export TO writeaccess;

