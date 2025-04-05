--
-- Name: t_cached_experiment_stats; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_experiment_stats (
    exp_id integer NOT NULL,
    dataset_count integer DEFAULT 0 NOT NULL,
    factor_count integer DEFAULT 0 NOT NULL,
    most_recent_dataset timestamp without time zone,
    update_required smallint DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_cached_experiment_stats OWNER TO d3l243;

--
-- Name: t_cached_experiment_stats pk_t_cached_experiment_stats; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_experiment_stats
    ADD CONSTRAINT pk_t_cached_experiment_stats PRIMARY KEY (exp_id);

ALTER TABLE public.t_cached_experiment_stats CLUSTER ON pk_t_cached_experiment_stats;

--
-- Name: ix_t_cached_experiment_stats_update_required; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_cached_experiment_stats_update_required ON public.t_cached_experiment_stats USING btree (update_required);

--
-- Name: t_cached_experiment_stats trig_t_cached_experiment_stats_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_cached_experiment_stats_after_update AFTER UPDATE ON public.t_cached_experiment_stats FOR EACH ROW WHEN (((old.dataset_count <> new.dataset_count) OR (old.factor_count <> new.factor_count) OR (old.most_recent_dataset IS DISTINCT FROM new.most_recent_dataset))) EXECUTE FUNCTION public.trigfn_t_cached_experiment_stats_after_update();

--
-- Name: t_cached_experiment_stats fk_t_cached_experiment_stats_t_experiments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_experiment_stats
    ADD CONSTRAINT fk_t_cached_experiment_stats_t_experiments FOREIGN KEY (exp_id) REFERENCES public.t_experiments(exp_id) ON DELETE CASCADE;

--
-- Name: TABLE t_cached_experiment_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_experiment_stats TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_cached_experiment_stats TO writeaccess;

