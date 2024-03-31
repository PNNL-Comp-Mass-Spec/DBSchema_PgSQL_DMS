--
-- Name: v_eus_usage_type_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_usage_type_list_report AS
 SELECT eus_usage_type_id AS id,
    eus_usage_type,
    description,
    enabled,
    enabled_campaign,
    enabled_prep_request
   FROM public.t_eus_usage_type;


ALTER VIEW public.v_eus_usage_type_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_usage_type_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_usage_type_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_eus_usage_type_list_report TO writeaccess;

