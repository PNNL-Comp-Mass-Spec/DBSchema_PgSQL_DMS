--
-- Name: v_active_instrument_users; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_instrument_users AS
 SELECT DISTINCT u.username,
    u.name,
    u.username AS payroll_num
   FROM ((public.t_users u
     JOIN public.t_user_operations_permissions ops_permissions ON ((u.user_id = ops_permissions.user_id)))
     JOIN public.t_user_operations ops ON ((ops_permissions.operation_id = ops.operation_id)))
  WHERE ((u.status OPERATOR(public.=) 'Active'::public.citext) AND (ops.operation OPERATOR(public.=) ANY (ARRAY['DMS_Instrument_Operation'::public.citext, 'DMS_Infrastructure_Administration'::public.citext, 'DMS_Dataset_Operation'::public.citext])));


ALTER VIEW public.v_active_instrument_users OWNER TO d3l243;

--
-- Name: VIEW v_active_instrument_users; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_active_instrument_users IS 'Column payroll_num is a deprecated name for username';

--
-- Name: TABLE v_active_instrument_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_active_instrument_users TO readaccess;
GRANT SELECT ON TABLE public.v_active_instrument_users TO writeaccess;

