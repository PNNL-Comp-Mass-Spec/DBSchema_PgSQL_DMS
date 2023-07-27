--
-- Name: v_req_run_instrument_picklist_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_req_run_instrument_picklist_ex AS
 SELECT t_instrument_name.instrument AS val,
    ''::text AS ex
   FROM public.t_instrument_name
  WHERE ((NOT (t_instrument_name.instrument OPERATOR(public.~~) 'SW_%'::public.citext)) AND (t_instrument_name.status OPERATOR(public.=) 'active'::public.citext) AND (t_instrument_name.operations_role OPERATOR(public.<>) 'QC'::public.citext))
UNION
 SELECT 'LCQ'::public.citext AS val,
    ''::text AS ex;


ALTER TABLE public.v_req_run_instrument_picklist_ex OWNER TO d3l243;

--
-- Name: TABLE v_req_run_instrument_picklist_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_req_run_instrument_picklist_ex TO readaccess;
GRANT SELECT ON TABLE public.v_req_run_instrument_picklist_ex TO writeaccess;

