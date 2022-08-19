--
-- Name: t_biomaterial_tracking; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_biomaterial_tracking (
    biomaterial_id integer NOT NULL,
    experiment_count integer DEFAULT 0 NOT NULL,
    dataset_count integer DEFAULT 0 NOT NULL,
    job_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.t_biomaterial_tracking OWNER TO d3l243;

--
-- Name: t_biomaterial_tracking pk_t_biomaterial_tracking; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial_tracking
    ADD CONSTRAINT pk_t_biomaterial_tracking PRIMARY KEY (biomaterial_id);

--
-- Name: TABLE t_biomaterial_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_biomaterial_tracking TO readaccess;
GRANT SELECT ON TABLE public.t_biomaterial_tracking TO writeaccess;

