--
-- Name: t_cached_dataset_folder_paths; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_dataset_folder_paths (
    dataset_id integer NOT NULL,
    dataset_row_version xid,
    storage_path_row_version xid,
    dataset_folder_path public.citext,
    archive_folder_path public.citext,
    myemsl_path_flag public.citext,
    dataset_url public.citext,
    update_required smallint DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_cached_dataset_folder_paths OWNER TO d3l243;

--
-- Name: TABLE t_cached_dataset_folder_paths; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON TABLE public.t_cached_dataset_folder_paths IS 'dataset_row_version comes from t_dataset.xmin and storage_path_row_version comes from t_storage_path.xmin';

--
-- Name: t_cached_dataset_folder_paths pk_t_cached_dataset_folder_paths; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_folder_paths
    ADD CONSTRAINT pk_t_cached_dataset_folder_paths PRIMARY KEY (dataset_id);

--
-- Name: ix_t_cached_dataset_folder_paths_update_required; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_cached_dataset_folder_paths_update_required ON public.t_cached_dataset_folder_paths USING btree (update_required);

--
-- Name: t_cached_dataset_folder_paths trig_t_cached_dataset_folder_paths_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_cached_dataset_folder_paths_after_update AFTER UPDATE ON public.t_cached_dataset_folder_paths FOR EACH ROW WHEN (((old.dataset_row_version IS DISTINCT FROM new.dataset_row_version) OR (old.storage_path_row_version IS DISTINCT FROM new.storage_path_row_version) OR (old.dataset_folder_path IS DISTINCT FROM new.dataset_folder_path) OR (old.archive_folder_path IS DISTINCT FROM new.archive_folder_path) OR (old.myemsl_path_flag IS DISTINCT FROM new.myemsl_path_flag) OR (old.dataset_url IS DISTINCT FROM new.dataset_url))) EXECUTE FUNCTION public.trigfn_t_cached_dataset_folder_paths_after_update();

--
-- Name: t_cached_dataset_folder_paths fk_t_cached_dataset_folder_paths_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_folder_paths
    ADD CONSTRAINT fk_t_cached_dataset_folder_paths_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id) ON DELETE CASCADE;

--
-- Name: TABLE t_cached_dataset_folder_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_dataset_folder_paths TO readaccess;
GRANT SELECT ON TABLE public.t_cached_dataset_folder_paths TO writeaccess;

