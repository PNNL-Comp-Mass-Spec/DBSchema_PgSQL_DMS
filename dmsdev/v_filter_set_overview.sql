--
-- Name: v_filter_set_overview; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_set_overview AS
 SELECT fst.filter_type_id,
    fst.filter_type_name,
    fs.filter_set_id,
    fs.filter_set_name,
    fs.filter_set_description
   FROM (public.t_filter_sets fs
     JOIN public.t_filter_set_types fst ON ((fs.filter_type_id = fst.filter_type_id)));


ALTER VIEW public.v_filter_set_overview OWNER TO d3l243;

--
-- Name: TABLE v_filter_set_overview; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_set_overview TO readaccess;
GRANT SELECT ON TABLE public.v_filter_set_overview TO writeaccess;

