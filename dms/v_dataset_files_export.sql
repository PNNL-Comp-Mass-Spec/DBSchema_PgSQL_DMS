--
-- Name: v_dataset_files_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_files_export AS
 SELECT dataset_file_id,
    dataset_id,
    file_path,
    file_size_bytes,
    file_hash,
    file_size_rank,
    allow_duplicates
   FROM public.t_dataset_files df
  WHERE (deleted = false);


ALTER VIEW public.v_dataset_files_export OWNER TO d3l243;

--
-- Name: TABLE v_dataset_files_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_files_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_files_export TO writeaccess;

