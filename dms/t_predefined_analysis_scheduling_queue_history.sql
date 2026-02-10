--
-- Name: t_predefined_analysis_scheduling_queue_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_queue_history (
    entry_id integer CONSTRAINT t_predefined_analysis_scheduling_queue_histor_entry_id_not_null NOT NULL,
    dataset_id integer CONSTRAINT t_predefined_analysis_scheduling_queue_hist_dataset_id_not_null NOT NULL,
    dataset_rating_id smallint CONSTRAINT t_predefined_analysis_scheduling_que_dataset_rating_id_not_null NOT NULL,
    jobs_created integer DEFAULT 0 CONSTRAINT t_predefined_analysis_scheduling_queue_hi_jobs_created_not_null NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_predefined_analysis_scheduling_queue_history OWNER TO d3l243;

--
-- Name: t_predefined_analysis_scheduling_queue_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_predefined_analysis_scheduling_queue_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_predefined_analysis_scheduling_queue_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_predefined_analysis_scheduling_queue_history pk_t_predefined_analysis_scheduling_queue_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis_scheduling_queue_history
    ADD CONSTRAINT pk_t_predefined_analysis_scheduling_queue_history PRIMARY KEY (entry_id);

ALTER TABLE public.t_predefined_analysis_scheduling_queue_history CLUSTER ON pk_t_predefined_analysis_scheduling_queue_history;

--
-- Name: ix_t_predefined_analysis_scheduling_queue_history_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_predefined_analysis_scheduling_queue_history_dataset_id ON public.t_predefined_analysis_scheduling_queue_history USING btree (dataset_id);

--
-- Name: ix_t_predefined_analysis_scheduling_queue_history_rating; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_predefined_analysis_scheduling_queue_history_rating ON public.t_predefined_analysis_scheduling_queue_history USING btree (dataset_rating_id);

--
-- Name: TABLE t_predefined_analysis_scheduling_queue_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_queue_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_predefined_analysis_scheduling_queue_history TO writeaccess;

