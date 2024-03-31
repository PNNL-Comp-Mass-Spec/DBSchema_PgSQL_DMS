--
-- Name: v_secondary_sep_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_secondary_sep_picklist AS
 SELECT separation_type_id AS id,
    separation_type AS name,
    comment,
    separation_group
   FROM public.t_secondary_sep
  WHERE (active > 0);


ALTER VIEW public.v_secondary_sep_picklist OWNER TO d3l243;

--
-- Name: TABLE v_secondary_sep_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_secondary_sep_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_secondary_sep_picklist TO writeaccess;

