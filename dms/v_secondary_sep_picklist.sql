--
-- Name: v_secondary_sep_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_secondary_sep_picklist AS
 SELECT t_secondary_sep.separation_type_id AS id,
    t_secondary_sep.separation_type AS name,
    t_secondary_sep.comment,
    t_secondary_sep.separation_group
   FROM public.t_secondary_sep
  WHERE (t_secondary_sep.active > 0);


ALTER TABLE public.v_secondary_sep_picklist OWNER TO d3l243;

--
-- Name: TABLE v_secondary_sep_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_secondary_sep_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_secondary_sep_picklist TO writeaccess;

