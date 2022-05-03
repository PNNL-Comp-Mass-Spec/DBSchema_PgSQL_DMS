--
-- Name: t_dataset_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_type_name (
    dataset_type_id integer NOT NULL,
    dataset_type public.citext NOT NULL,
    description public.citext,
    active smallint NOT NULL
);


ALTER TABLE public.t_dataset_type_name OWNER TO d3l243;

--
-- Name: t_dataset_type_name pk_t_dataset_type_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_type_name
    ADD CONSTRAINT pk_t_dataset_type_name PRIMARY KEY (dataset_type_id);

--
-- Name: ix_t_dataset_type_name_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_dataset_type_name_name ON public.t_dataset_type_name USING btree (dataset_type);

--
-- Name: TABLE t_dataset_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_type_name TO readaccess;

