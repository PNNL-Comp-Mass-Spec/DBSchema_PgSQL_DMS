--
-- Name: v_secondary_sep_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_secondary_sep_export AS
 SELECT t_secondary_sep.separation_type_id,
    t_secondary_sep.separation_type,
    t_secondary_sep.comment,
    t_secondary_sep.active,
    t_secondary_sep.separation_group,
    t_secondary_sep.sample_type_id
   FROM public.t_secondary_sep;


ALTER VIEW public.v_secondary_sep_export OWNER TO d3l243;

--
-- Name: TABLE v_secondary_sep_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_secondary_sep_export TO readaccess;
GRANT SELECT ON TABLE public.v_secondary_sep_export TO writeaccess;

