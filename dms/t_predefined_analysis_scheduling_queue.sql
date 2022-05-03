--
-- Name: t_predefined_analysis_scheduling_queue; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_queue (
    item integer NOT NULL,
    dataset_id integer NOT NULL,
    calling_user public.citext,
    analysis_tool_name_filter public.citext,
    exclude_datasets_not_released smallint,
    prevent_duplicate_jobs smallint,
    state public.citext NOT NULL,
    result_code integer,
    message public.citext,
    jobs_created integer NOT NULL,
    entered timestamp without time zone NOT NULL,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_predefined_analysis_scheduling_queue OWNER TO d3l243;

--
-- Name: t_predefined_analysis_scheduling_queue pk_t_predefined_analysis_scheduling_queue; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis_scheduling_queue
    ADD CONSTRAINT pk_t_predefined_analysis_scheduling_queue PRIMARY KEY (item);

--
-- Name: ix_t_predefined_analysis_scheduling_queue_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_predefined_analysis_scheduling_queue_dataset_id ON public.t_predefined_analysis_scheduling_queue USING btree (dataset_id);

--
-- Name: ix_t_predefined_analysis_scheduling_queue_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_predefined_analysis_scheduling_queue_state ON public.t_predefined_analysis_scheduling_queue USING btree (state);

--
-- Name: TABLE t_predefined_analysis_scheduling_queue; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_queue TO readaccess;

