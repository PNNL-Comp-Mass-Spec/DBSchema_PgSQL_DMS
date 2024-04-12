--
-- Name: v_instrument_info_lcmsnet; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_info_lcmsnet AS
 SELECT i.instrument,
    (((i.instrument)::text || (
        CASE
            WHEN (i.usage OPERATOR(public.=) ''::public.citext) THEN ''::public.citext
            ELSE (((' '::public.citext)::text || (i.usage)::text))::public.citext
        END)::text))::public.citext AS name_and_usage,
    i.instrument_group,
    i.status,
    tp.machine_name AS host_name,
    tp.vol_name_server AS server_path,
    tp.storage_path AS share_path,
    i.capture_method
   FROM (public.t_instrument_name i
     JOIN public.t_storage_path tp ON ((i.source_path_id = tp.storage_path_id)))
  WHERE ((i.instrument OPERATOR(public.!~) similar_to_escape(('SW[_]%'::public.citext)::text)) AND (i.status OPERATOR(public.=) 'active'::public.citext) AND (i.operations_role OPERATOR(public.<>) 'QC'::public.citext));


ALTER VIEW public.v_instrument_info_lcmsnet OWNER TO d3l243;

--
-- Name: TABLE v_instrument_info_lcmsnet; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_info_lcmsnet TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_info_lcmsnet TO writeaccess;

