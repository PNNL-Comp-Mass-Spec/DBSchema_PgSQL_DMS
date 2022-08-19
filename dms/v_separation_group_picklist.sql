--
-- Name: v_separation_group_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_separation_group_picklist AS
 SELECT t_separation_group.separation_group,
    t_separation_group.sample_prep_visible,
    t_separation_group.fraction_count
   FROM public.t_separation_group
  WHERE (t_separation_group.active > 0);


ALTER TABLE public.v_separation_group_picklist OWNER TO d3l243;

--
-- Name: TABLE v_separation_group_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_separation_group_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_separation_group_picklist TO writeaccess;

