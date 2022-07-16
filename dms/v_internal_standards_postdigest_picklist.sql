--
-- Name: v_internal_standards_postdigest_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_internal_standards_postdigest_picklist AS
 SELECT t_internal_standards.internal_standard_id AS id,
    t_internal_standards.name,
    t_internal_standards.description
   FROM public.t_internal_standards
  WHERE ((t_internal_standards.active = 'A'::bpchar) AND (t_internal_standards.type OPERATOR(public.=) ANY (ARRAY['Postdigest'::public.citext, 'All'::public.citext])) AND (t_internal_standards.internal_standard_id > 0));


ALTER TABLE public.v_internal_standards_postdigest_picklist OWNER TO d3l243;

--
-- Name: TABLE v_internal_standards_postdigest_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_internal_standards_postdigest_picklist TO readaccess;

