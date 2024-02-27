--
-- Name: t_protein_collection_usage; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_protein_collection_usage (
    protein_collection_id integer NOT NULL,
    name public.citext,
    job_usage_count integer,
    job_usage_count_last12months integer,
    most_recently_used timestamp without time zone
);


ALTER TABLE public.t_protein_collection_usage OWNER TO d3l243;

--
-- Name: t_protein_collection_usage pk_t_protein_collection_usage; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_protein_collection_usage
    ADD CONSTRAINT pk_t_protein_collection_usage PRIMARY KEY (protein_collection_id);

--
-- Name: ix_t_protein_collection_usage_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_protein_collection_usage_name ON public.t_protein_collection_usage USING btree (name);

--
-- Name: TABLE t_protein_collection_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_protein_collection_usage TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_protein_collection_usage TO writeaccess;

