--
-- Name: v_eus_usage_type_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_usage_type_list_report AS
 SELECT t_eus_usage_type.eus_usage_type_id AS id,
    t_eus_usage_type.eus_usage_type,
    t_eus_usage_type.description,
    t_eus_usage_type.enabled,
    t_eus_usage_type.enabled_campaign,
    t_eus_usage_type.enabled_prep_request
   FROM public.t_eus_usage_type;


ALTER TABLE public.v_eus_usage_type_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_usage_type_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_usage_type_list_report TO readaccess;

