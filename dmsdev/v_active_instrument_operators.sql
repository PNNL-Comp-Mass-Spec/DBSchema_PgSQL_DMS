--
-- Name: v_active_instrument_operators; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_instrument_operators AS
 SELECT username,
    name,
    username AS payroll_num
   FROM public.v_active_instrument_users;


ALTER VIEW public.v_active_instrument_operators OWNER TO d3l243;

--
-- Name: VIEW v_active_instrument_operators; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_active_instrument_operators IS 'Column payroll_num is a deprecated name for username';

--
-- Name: TABLE v_active_instrument_operators; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_active_instrument_operators TO readaccess;
GRANT SELECT ON TABLE public.v_active_instrument_operators TO writeaccess;

