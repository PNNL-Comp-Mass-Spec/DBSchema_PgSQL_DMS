--
-- Name: v_eus_usage_type_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_usage_type_picklist AS
 SELECT eus_usage_type_id AS id,
    eus_usage_type AS name,
    description,
    enabled_campaign,
    enabled_prep_request
   FROM public.t_eus_usage_type
  WHERE ((eus_usage_type_id > 1) AND (enabled > 0));


ALTER VIEW public.v_eus_usage_type_picklist OWNER TO d3l243;

--
-- Name: TABLE v_eus_usage_type_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_usage_type_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_eus_usage_type_picklist TO writeaccess;

