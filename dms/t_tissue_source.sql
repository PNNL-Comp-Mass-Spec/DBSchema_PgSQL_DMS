--
-- Name: t_tissue_source; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_tissue_source (
    tissue_source_id smallint NOT NULL,
    tissue_source public.citext NOT NULL
);


ALTER TABLE public.t_tissue_source OWNER TO d3l243;

--
-- Name: t_tissue_source pk_t_tissue_source; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_tissue_source
    ADD CONSTRAINT pk_t_tissue_source PRIMARY KEY (tissue_source_id);

--
-- Name: TABLE t_tissue_source; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_tissue_source TO readaccess;

