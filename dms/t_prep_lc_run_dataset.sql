--
-- Name: t_prep_lc_run_dataset; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_prep_lc_run_dataset (
    prep_lc_run_id integer NOT NULL,
    dataset_id integer NOT NULL
);


ALTER TABLE public.t_prep_lc_run_dataset OWNER TO d3l243;

--
-- Name: t_prep_lc_run_prep_run_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_prep_lc_run ALTER COLUMN prep_run_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_prep_lc_run_prep_run_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_prep_lc_run_dataset pk_t_prep_lc_run_dataset; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_run_dataset
    ADD CONSTRAINT pk_t_prep_lc_run_dataset PRIMARY KEY (prep_lc_run_id, dataset_id);

--
-- Name: TABLE t_prep_lc_run_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_lc_run_dataset TO readaccess;

