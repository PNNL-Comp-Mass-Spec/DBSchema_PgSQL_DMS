--
-- Name: t_cached_dataset_stats; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_dataset_stats (
    dataset_id integer NOT NULL,
    instrument_id integer NOT NULL,
    instrument public.citext NOT NULL,
    job_count integer DEFAULT 0 NOT NULL,
    psm_job_count integer DEFAULT 0 NOT NULL,
    update_required smallint DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_cached_dataset_stats OWNER TO d3l243;

--
-- Name: t_cached_dataset_stats pk_t_cached_dataset_stats; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_stats
    ADD CONSTRAINT pk_t_cached_dataset_stats PRIMARY KEY (dataset_id);

--
-- Name: ix_t_cached_dataset_stats_instrument_id_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_cached_dataset_stats_instrument_id_dataset_id ON public.t_cached_dataset_stats USING btree (instrument_id, dataset_id);

--
-- Name: ix_t_cached_dataset_stats_instrument_name_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_cached_dataset_stats_instrument_name_dataset_id ON public.t_cached_dataset_stats USING btree (instrument, dataset_id);

--
-- Name: t_cached_dataset_stats trig_t_cached_dataset_stats_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_cached_dataset_stats_after_update AFTER UPDATE ON public.t_cached_dataset_stats FOR EACH ROW WHEN (((old.job_count <> new.job_count) OR (old.psm_job_count <> new.psm_job_count) OR (old.instrument_id <> new.instrument_id) OR (old.instrument OPERATOR(public.<>) new.instrument))) EXECUTE FUNCTION public.trigfn_t_cached_dataset_stats_after_update();

--
-- Name: t_cached_dataset_stats fk_t_cached_dataset_stats_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_stats
    ADD CONSTRAINT fk_t_cached_dataset_stats_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: t_cached_dataset_stats fk_t_cached_dataset_stats_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_dataset_stats
    ADD CONSTRAINT fk_t_cached_dataset_stats_t_instrument_name FOREIGN KEY (instrument_id) REFERENCES public.t_instrument_name(instrument_id);

--
-- Name: TABLE t_cached_dataset_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_dataset_stats TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_cached_dataset_stats TO writeaccess;

