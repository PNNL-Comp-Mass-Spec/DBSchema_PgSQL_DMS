--
-- Name: v_long_interval_threshold; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_long_interval_threshold AS
 SELECT public.get_long_interval_threshold() AS threshold_minutes;


ALTER VIEW public.v_long_interval_threshold OWNER TO d3l243;

--
-- Name: TABLE v_long_interval_threshold; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_long_interval_threshold TO readaccess;
GRANT SELECT ON TABLE public.v_long_interval_threshold TO writeaccess;

