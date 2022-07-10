--
-- Name: v_dataset_files_recent; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_files_recent AS
 SELECT df.dataset_id,
    ds.dataset,
    df.file_hash,
    ds.created AS dataset_created
   FROM (public.t_dataset_files df
     JOIN public.t_dataset ds ON ((ds.dataset_id = df.dataset_id)))
  WHERE ((df.allow_duplicates = false) AND (df.deleted = false) AND (ds.created >= (CURRENT_TIMESTAMP - '180 days'::interval)));


ALTER TABLE public.v_dataset_files_recent OWNER TO d3l243;

--
-- Name: TABLE v_dataset_files_recent; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_files_recent TO readaccess;

