--
-- Name: v_lc_column_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_column_picklist AS
 SELECT lc_column AS val,
    ''::text AS ex
   FROM public.t_lc_column
  WHERE (column_state_id = 2);


ALTER VIEW public.v_lc_column_picklist OWNER TO d3l243;

--
-- Name: TABLE v_lc_column_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_column_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_lc_column_picklist TO writeaccess;

