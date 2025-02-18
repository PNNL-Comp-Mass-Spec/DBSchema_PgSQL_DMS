--
-- Name: v_instrument_info_lcmsnet; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_info_lcmsnet AS
 SELECT instname.instrument,
    (((instname.instrument)::text || (
        CASE
            WHEN (instname.usage OPERATOR(public.=) ''::public.citext) THEN ''::public.citext
            ELSE (((' '::public.citext)::text || (instname.usage)::text))::public.citext
        END)::text))::public.citext AS name_and_usage,
    instname.instrument_group,
    instname.status,
    spath.machine_name AS host_name,
    spath.vol_name_server AS server_path,
    spath.storage_path AS share_path,
    instname.capture_method
   FROM (public.t_instrument_name instname
     JOIN public.t_storage_path spath ON ((instname.source_path_id = spath.storage_path_id)))
  WHERE ((instname.instrument OPERATOR(public.!~) similar_to_escape(('SW[_]%'::public.citext)::text)) AND (instname.status OPERATOR(public.=) 'active'::public.citext) AND (instname.operations_role OPERATOR(public.<>) 'QC'::public.citext));


ALTER VIEW public.v_instrument_info_lcmsnet OWNER TO d3l243;

--
-- Name: TABLE v_instrument_info_lcmsnet; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_info_lcmsnet TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_info_lcmsnet TO writeaccess;

