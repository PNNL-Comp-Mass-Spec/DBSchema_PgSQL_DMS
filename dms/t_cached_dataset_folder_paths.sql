--
-- Name: t_cached_dataset_folder_paths; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_dataset_folder_paths (
    dataset_id integer NOT NULL,
    dataset_row_version xid NOT NULL,
    storage_path_row_version xid,
    dataset_folder_path public.citext,
    archive_folder_path public.citext,
    myemsl_path_flag public.citext,
    dataset_url public.citext,
    update_required smallint NOT NULL,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_cached_dataset_folder_paths OWNER TO d3l243;

--
-- Name: TABLE t_cached_dataset_folder_paths; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON TABLE public.t_cached_dataset_folder_paths IS 'dataset_row_version comes from t_dataset.xmin and storage_path_row_version comes from t_storage_path.xmin';

--
-- Name: TABLE t_cached_dataset_folder_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_dataset_folder_paths TO readaccess;

