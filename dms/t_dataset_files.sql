--
-- Name: t_dataset_files; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_files (
    dataset_file_id integer NOT NULL,
    dataset_id integer NOT NULL,
    file_path public.citext NOT NULL,
    file_size_bytes bigint,
    file_hash public.citext,
    file_size_rank smallint,
    allow_duplicates boolean,
    deleted boolean
);


ALTER TABLE public.t_dataset_files OWNER TO d3l243;

--
-- Name: TABLE t_dataset_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_files TO readaccess;

