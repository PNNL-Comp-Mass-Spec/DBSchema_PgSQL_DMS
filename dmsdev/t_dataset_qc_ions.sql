--
-- Name: t_dataset_qc_ions; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_qc_ions (
    dataset_id integer NOT NULL,
    mz double precision NOT NULL,
    max_intensity real,
    median_intensity real
);


ALTER TABLE public.t_dataset_qc_ions OWNER TO d3l243;

--
-- Name: t_dataset_qc_ions pk_t_dataset_qc_ions_dataset_id; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_qc_ions
    ADD CONSTRAINT pk_t_dataset_qc_ions_dataset_id PRIMARY KEY (dataset_id, mz);

--
-- Name: TABLE t_dataset_qc_ions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_qc_ions TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_qc_ions TO writeaccess;

