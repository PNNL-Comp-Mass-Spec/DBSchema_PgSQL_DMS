--
-- Name: t_cached_dataset_links; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_dataset_links (
    dataset_id integer NOT NULL,
    dataset_row_version xid,
    storage_path_row_version xid,
    dataset_folder_path public.citext,
    archive_folder_path public.citext,
    myemsl_url public.citext,
    qc_link public.citext,
    qc_2d public.citext,
    qc_metric_stats public.citext,
    masic_directory_name public.citext,
    update_required smallint DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_cached_dataset_links OWNER TO d3l243;

--
-- Name: TABLE t_cached_dataset_links; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON TABLE public.t_cached_dataset_links IS 'dataset_row_version comes from t_dataset.xmin and storage_path_row_version comes from t_storage_path.xmin';

--
-- Name: t_cached_dataset_links pk_t_cached_dataset_links; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_links
    ADD CONSTRAINT pk_t_cached_dataset_links PRIMARY KEY (dataset_id);

ALTER TABLE public.t_cached_dataset_links CLUSTER ON pk_t_cached_dataset_links;

--
-- Name: ix_t_cached_dataset_links_update_required; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_cached_dataset_links_update_required ON public.t_cached_dataset_links USING btree (update_required);

--
-- Name: t_cached_dataset_links fk_t_cached_dataset_links_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_links
    ADD CONSTRAINT fk_t_cached_dataset_links_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id) ON DELETE CASCADE;

--
-- Name: TABLE t_cached_dataset_links; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_dataset_links TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_cached_dataset_links TO writeaccess;

