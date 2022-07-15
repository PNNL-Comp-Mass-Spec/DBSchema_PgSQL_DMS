--
-- Name: v_instrument_source_paths; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_source_paths AS
 SELECT spath.vol_name_server AS vol,
    spath.storage_path AS path,
    instname.capture_method AS method,
    instname.instrument
   FROM (public.t_instrument_name instname
     JOIN public.t_storage_path spath ON ((instname.source_path_id = spath.storage_path_id)))
  WHERE ((instname.status = 'active'::bpchar) AND (instname.scan_source_dir > 0));


ALTER TABLE public.v_instrument_source_paths OWNER TO d3l243;

--
-- Name: TABLE v_instrument_source_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_source_paths TO readaccess;

