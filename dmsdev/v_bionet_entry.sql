--
-- Name: v_bionet_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_bionet_entry AS
 SELECT host,
    ip,
    alias,
    entered,
    last_online,
    instruments,
    active,
    tag,
    comment
   FROM public.t_bionet_hosts go;


ALTER VIEW public.v_bionet_entry OWNER TO d3l243;

--
-- Name: TABLE v_bionet_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_bionet_entry TO readaccess;
GRANT SELECT ON TABLE public.v_bionet_entry TO writeaccess;

