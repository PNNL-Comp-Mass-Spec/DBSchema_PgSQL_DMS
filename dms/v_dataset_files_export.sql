--
-- Name: v_dataset_files_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_files_export AS
 SELECT df.dataset_file_id,
    df.dataset_id,
    df.file_path,
    df.file_size_bytes,
    df.file_hash,
    df.file_size_rank,
    df.allow_duplicates
   FROM public.t_dataset_files df
  WHERE (df.deleted = false);


ALTER TABLE public.v_dataset_files_export OWNER TO d3l243;

--
-- Name: TABLE v_dataset_files_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_files_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_files_export TO writeaccess;

