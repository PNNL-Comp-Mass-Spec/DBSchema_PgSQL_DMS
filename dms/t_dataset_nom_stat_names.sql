--
-- Name: t_dataset_nom_stat_names; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_nom_stat_names (
    metric public.citext NOT NULL,
    source public.citext NOT NULL,
    category public.citext,
    short_description public.citext,
    metric_value public.citext,
    units public.citext NOT NULL,
    optimal public.citext,
    purpose public.citext,
    description public.citext NOT NULL,
    ignored smallint DEFAULT 0,
    sort_key integer NOT NULL
);


ALTER TABLE public.t_dataset_nom_stat_names OWNER TO d3l243;

--
-- Name: t_dataset_nom_stat_names pk_t_dataset_nom_stat_names; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_nom_stat_names
    ADD CONSTRAINT pk_t_dataset_nom_stat_names PRIMARY KEY (metric);

ALTER TABLE public.t_dataset_nom_stat_names CLUSTER ON pk_t_dataset_nom_stat_names;

--
-- Name: ix_t_dataset_nom_stat_names_sort_key; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_nom_stat_names_sort_key ON public.t_dataset_nom_stat_names USING btree (sort_key);

--
-- Name: ix_t_dataset_nom_stat_names_source_metric; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_dataset_nom_stat_names_source_metric ON public.t_dataset_nom_stat_names USING btree (source, metric);

--
-- Name: TABLE t_dataset_nom_stat_names; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_nom_stat_names TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_nom_stat_names TO writeaccess;

