--
-- Name: v_bionet_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_bionet_list_report AS
 SELECT h.host,
    h.ip,
    h.alias,
    h.tag,
    h.entered,
    h.last_online,
    h.comment,
        CASE
            WHEN (char_length((h.instruments)::text) > 70) THEN ("left"((h.instruments)::text, 66) || ' ...'::text)
            ELSE (h.instruments)::text
        END AS instruments,
    t_yes_no.description AS active
   FROM (public.t_bionet_hosts h
     JOIN public.t_yes_no ON ((h.active = t_yes_no.flag)));


ALTER TABLE public.v_bionet_list_report OWNER TO d3l243;

--
-- Name: TABLE v_bionet_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_bionet_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_bionet_list_report TO writeaccess;

