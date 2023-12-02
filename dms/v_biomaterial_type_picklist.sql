--
-- Name: v_biomaterial_type_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_type_picklist AS
 SELECT btn.biomaterial_type_id AS id,
    btn.biomaterial_type
   FROM public.t_biomaterial_type_name btn;


ALTER VIEW public.v_biomaterial_type_picklist OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_type_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_type_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_type_picklist TO writeaccess;

