--
-- Name: v_data_analysis_request_user_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_user_picklist AS
 SELECT u.name AS val,
    u.name_with_username AS ex,
    u.username AS prn
   FROM ((public.t_users u
     JOIN public.t_user_operations_permissions uop ON ((u.user_id = uop.user_id)))
     JOIN public.t_user_operations uo ON ((uop.operation_id = uo.operation_id)))
  WHERE ((u.status OPERATOR(public.=) 'Active'::public.citext) AND (uo.operation OPERATOR(public.=) 'DMS_Data_Analysis_Request'::public.citext));


ALTER TABLE public.v_data_analysis_request_user_picklist OWNER TO d3l243;

--
-- Name: TABLE v_data_analysis_request_user_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_user_picklist TO readaccess;

