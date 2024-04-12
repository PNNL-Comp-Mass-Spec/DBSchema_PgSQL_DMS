--
-- Name: v_instrument_ops_role_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_ops_role_picklist AS
 SELECT DISTINCT operations_role AS val
   FROM public.t_instrument_name;


ALTER VIEW public.v_instrument_ops_role_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_ops_role_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_ops_role_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_ops_role_picklist TO writeaccess;

