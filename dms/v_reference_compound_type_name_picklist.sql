--
-- Name: v_reference_compound_type_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_reference_compound_type_name_picklist AS
 SELECT compound_type_id AS id,
    compound_type_name AS name
   FROM public.t_reference_compound_type_name;


ALTER VIEW public.v_reference_compound_type_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_reference_compound_type_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_reference_compound_type_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_reference_compound_type_name_picklist TO writeaccess;

