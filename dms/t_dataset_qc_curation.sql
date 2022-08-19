--
-- Name: t_dataset_qc_curation; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_qc_curation (
    dataset_id integer NOT NULL,
    dataset public.citext NOT NULL,
    dataset_type public.citext NOT NULL,
    instrument_category public.citext NOT NULL,
    used_for_training public.citext,
    used_for_testing public.citext,
    used_for_validation public.citext,
    curated_quality public.citext NOT NULL,
    curated_comment public.citext,
    pride_accession public.citext
);


ALTER TABLE public.t_dataset_qc_curation OWNER TO d3l243;

--
-- Name: t_dataset_qc_curation pk_t_dataset_qc_curation; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_qc_curation
    ADD CONSTRAINT pk_t_dataset_qc_curation PRIMARY KEY (dataset_id);

--
-- Name: TABLE t_dataset_qc_curation; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_qc_curation TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_qc_curation TO writeaccess;

