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
    allow_duplicates boolean DEFAULT false,
    deleted boolean DEFAULT false
);


ALTER TABLE public.t_dataset_files OWNER TO d3l243;

--
-- Name: t_dataset_files_dataset_file_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_dataset_files ALTER COLUMN dataset_file_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_dataset_files_dataset_file_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dataset_files pk_t_dataset_files; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_files
    ADD CONSTRAINT pk_t_dataset_files PRIMARY KEY (dataset_file_id);

--
-- Name: ix_t_dataset_files_dataset_id_file_path; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_dataset_files_dataset_id_file_path ON public.t_dataset_files USING btree (dataset_id, file_path);

--
-- Name: TABLE t_dataset_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_files TO readaccess;

