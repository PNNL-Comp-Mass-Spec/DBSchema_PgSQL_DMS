--
-- Name: v_dataset_files_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_files_list_report AS
 SELECT df.dataset_id,
    ds.dataset,
    df.file_path,
    df.file_size_bytes,
    df.file_hash,
    df.file_size_rank,
    instname.instrument,
    df.dataset_file_id
   FROM ((public.t_dataset_files df
     JOIN public.t_dataset ds ON ((df.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
  WHERE (df.deleted = false);


ALTER VIEW public.v_dataset_files_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_files_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_files_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_files_list_report TO writeaccess;

