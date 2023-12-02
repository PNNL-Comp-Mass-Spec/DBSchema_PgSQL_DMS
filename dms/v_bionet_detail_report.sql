--
-- Name: v_bionet_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_bionet_detail_report AS
 SELECT h.host,
    h.ip,
    '255.255.254.0'::text AS subnet_mask,
    '(leave blank)'::text AS default_gateway,
    '192.168.30.68'::text AS dns_server,
    h.alias,
    h.tag,
    h.entered,
    h.last_online,
    h.comment,
    h.instruments,
    h.instruments AS instrument_datasets,
    instname.room_number AS room,
    t_yes_no.description AS active
   FROM ((public.t_bionet_hosts h
     JOIN public.t_yes_no ON ((h.active = t_yes_no.flag)))
     LEFT JOIN public.t_instrument_name instname ON ((h.instruments OPERATOR(public.=) instname.instrument)));


ALTER VIEW public.v_bionet_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_bionet_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_bionet_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_bionet_detail_report TO writeaccess;

