--
-- Name: v_lc_column_state_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_column_state_picklist AS
 SELECT column_state AS val,
    ''::text AS ex
   FROM public.t_lc_column_state_name;


ALTER VIEW public.v_lc_column_state_picklist OWNER TO d3l243;

--
-- Name: TABLE v_lc_column_state_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_column_state_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_lc_column_state_picklist TO writeaccess;

