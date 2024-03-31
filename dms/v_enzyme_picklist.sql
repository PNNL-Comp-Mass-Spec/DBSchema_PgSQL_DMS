--
-- Name: v_enzyme_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_enzyme_picklist AS
 SELECT enzyme_id AS id,
    enzyme_name AS name
   FROM public.t_enzymes
  WHERE (enzyme_id > 0);


ALTER VIEW public.v_enzyme_picklist OWNER TO d3l243;

--
-- Name: TABLE v_enzyme_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_enzyme_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_enzyme_picklist TO writeaccess;

