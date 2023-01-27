--
-- Name: v_bionet_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_bionet_entry AS
 SELECT go.host,
    go.ip,
    go.alias,
    go.entered,
    go.last_online,
    go.instruments,
    go.active,
    go.tag,
    go.comment
   FROM public.t_bionet_hosts go;


ALTER TABLE public.v_bionet_entry OWNER TO d3l243;

--
-- Name: TABLE v_bionet_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_bionet_entry TO readaccess;
GRANT SELECT ON TABLE public.v_bionet_entry TO writeaccess;

