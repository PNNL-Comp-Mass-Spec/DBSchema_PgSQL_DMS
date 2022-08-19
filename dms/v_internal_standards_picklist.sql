--
-- Name: v_internal_standards_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_internal_standards_picklist AS
 SELECT t_internal_standards.name AS val,
    ''::text AS ex
   FROM public.t_internal_standards
  WHERE (t_internal_standards.internal_standard_id > 0);


ALTER TABLE public.v_internal_standards_picklist OWNER TO d3l243;

--
-- Name: TABLE v_internal_standards_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_internal_standards_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_internal_standards_picklist TO writeaccess;

