--
-- Name: v_instrument_source_scan_dir; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_source_scan_dir AS
 SELECT t_misc_paths.server AS scan_file_dir
   FROM public.t_misc_paths
  WHERE (t_misc_paths.path_function = 'InstrumentSourceScanDir'::bpchar);


ALTER TABLE public.v_instrument_source_scan_dir OWNER TO d3l243;

--
-- Name: TABLE v_instrument_source_scan_dir; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_source_scan_dir TO readaccess;

