--
-- Name: v_internal_standards_predigest_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_internal_standards_predigest_picklist AS
 SELECT internal_standard_id AS id,
    name,
    description
   FROM public.t_internal_standards
  WHERE ((active OPERATOR(public.=) 'A'::public.citext) AND (type OPERATOR(public.=) ANY (ARRAY['Predigest'::public.citext, 'All'::public.citext])) AND (internal_standard_id > 0));


ALTER VIEW public.v_internal_standards_predigest_picklist OWNER TO d3l243;

--
-- Name: TABLE v_internal_standards_predigest_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_internal_standards_predigest_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_internal_standards_predigest_picklist TO writeaccess;

