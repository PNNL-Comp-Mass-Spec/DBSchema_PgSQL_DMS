--
-- Name: t_cached_requested_run_batch_stats; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_requested_run_batch_stats (
    batch_id integer NOT NULL,
    requests integer,
    instrument_group_first text,
    instrument_group_last text,
    separation_group_first text,
    separation_group_last text,
    active_requests integer,
    first_active_request integer,
    last_active_request integer,
    oldest_request_created timestamp without time zone,
    oldest_active_request_created timestamp without time zone,
    datasets integer,
    instrument_first text,
    instrument_last text,
    days_in_queue integer,
    min_days_in_queue integer,
    max_days_in_queue integer,
    days_in_prep_queue integer,
    blocked integer,
    block_missing integer,
    last_affected timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_cached_requested_run_batch_stats OWNER TO d3l243;

--
-- Name: t_cached_requested_run_batch_stats pk_t_cached_requested_run_batch_stats; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_requested_run_batch_stats
    ADD CONSTRAINT pk_t_cached_requested_run_batch_stats PRIMARY KEY (batch_id);

--
-- Name: t_cached_requested_run_batch_stats fk_t_cached_requested_run_batch_stats_t_requested_run_batches; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_requested_run_batch_stats
    ADD CONSTRAINT fk_t_cached_requested_run_batch_stats_t_requested_run_batches FOREIGN KEY (batch_id) REFERENCES public.t_requested_run_batches(batch_id) ON DELETE CASCADE;

--
-- Name: TABLE t_cached_requested_run_batch_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_requested_run_batch_stats TO readaccess;
GRANT SELECT ON TABLE public.t_cached_requested_run_batch_stats TO writeaccess;

