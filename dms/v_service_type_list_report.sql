--
-- Name: v_service_type_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_type_list_report AS
 SELECT service_type_id,
    service_type,
    service_description,
    abbreviation
   FROM cc.t_service_type;


ALTER VIEW public.v_service_type_list_report OWNER TO d3l243;

--
-- Name: TABLE v_service_type_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_type_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_type_list_report TO writeaccess;

