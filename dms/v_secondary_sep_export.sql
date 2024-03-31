--
-- Name: v_secondary_sep_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_secondary_sep_export AS
 SELECT separation_type_id,
    separation_type,
    comment,
    active,
    separation_group,
    sample_type_id
   FROM public.t_secondary_sep;


ALTER VIEW public.v_secondary_sep_export OWNER TO d3l243;

--
-- Name: TABLE v_secondary_sep_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_secondary_sep_export TO readaccess;
GRANT SELECT ON TABLE public.v_secondary_sep_export TO writeaccess;

