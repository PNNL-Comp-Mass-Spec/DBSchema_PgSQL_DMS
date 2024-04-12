--
-- Name: v_separation_group_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_separation_group_picklist AS
 SELECT separation_group AS sep_group,
    sample_prep_visible,
    fraction_count
   FROM public.t_separation_group
  WHERE (active > 0);


ALTER VIEW public.v_separation_group_picklist OWNER TO d3l243;

--
-- Name: TABLE v_separation_group_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_separation_group_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_separation_group_picklist TO writeaccess;

