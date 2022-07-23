--
-- Name: v_myemsl_main_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_myemsl_main_metadata AS
 SELECT ds.dataset_id,
    ds.dataset AS dataset_name,
    ds.operator_prn AS submitter_prn,
    COALESCE(rr.eus_proposal_id, '17797'::public.citext) AS proposal_id,
    COALESCE(dmsinstmap.eus_instrument_id, 34127) AS instrument_id,
    ds.created AS dataset_ctime,
    COALESCE(ds.file_info_last_modified, ds.created) AS dataset_mtime
   FROM ((public.t_dataset ds
     LEFT JOIN public.t_requested_run rr ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_emsl_dms_instrument_mapping dmsinstmap ON ((dmsinstmap.dms_instrument_id = ds.instrument_id)));


ALTER TABLE public.v_myemsl_main_metadata OWNER TO d3l243;

--
-- Name: TABLE v_myemsl_main_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_myemsl_main_metadata TO readaccess;

