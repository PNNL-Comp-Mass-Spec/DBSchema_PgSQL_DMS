--
-- Name: v_instrument_source_scan_dir; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_source_scan_dir AS
 SELECT server AS scan_file_dir
   FROM public.t_misc_paths
  WHERE (path_function OPERATOR(public.=) 'InstrumentSourceScanDir'::public.citext);


ALTER VIEW public.v_instrument_source_scan_dir OWNER TO d3l243;

--
-- Name: TABLE v_instrument_source_scan_dir; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_source_scan_dir TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_source_scan_dir TO writeaccess;

