--
-- Name: v_service_type_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_type_picklist AS
 SELECT service_type_id,
    service_type,
    format('%s: %s'::text, service_type_id, service_type) AS service_type_with_id
   FROM svc.t_service_type;


ALTER VIEW public.v_service_type_picklist OWNER TO d3l243;

--
-- Name: TABLE v_service_type_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_type_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_service_type_picklist TO writeaccess;

