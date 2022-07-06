--
-- Name: v_old_storage_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_old_storage_report AS
 SELECT instname.instrument,
    ((spath.vol_name_client)::text || (spath.storage_path)::text) AS storage_path
   FROM (public.t_instrument_name instname
     JOIN public.t_storage_path spath ON ((instname.instrument OPERATOR(public.=) spath.instrument)))
  WHERE ((spath.storage_path_function)::text = ('old-storage'::bpchar)::text);


ALTER TABLE public.v_old_storage_report OWNER TO d3l243;

--
-- Name: TABLE v_old_storage_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_old_storage_report TO readaccess;

