--
-- Name: t_predefined_analysis_scheduling_queue; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_queue (
    item integer NOT NULL,
    dataset_id integer NOT NULL,
    calling_user public.citext DEFAULT SESSION_USER,
    analysis_tool_name_filter public.citext DEFAULT ''::public.citext,
    exclude_datasets_not_released smallint DEFAULT 1,
    prevent_duplicate_jobs smallint DEFAULT 1,
    state public.citext DEFAULT 'New'::public.citext NOT NULL,
    result_code integer,
    message public.citext,
    jobs_created integer DEFAULT 0 NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_predefined_analysis_scheduling_queue OWNER TO d3l243;

--
-- Name: t_predefined_analysis_scheduling_queue_item_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_predefined_analysis_scheduling_queue ALTER COLUMN item ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_predefined_analysis_scheduling_queue_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_predefined_analysis_scheduling_queue pk_t_predefined_analysis_scheduling_queue; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis_scheduling_queue
    ADD CONSTRAINT pk_t_predefined_analysis_scheduling_queue PRIMARY KEY (item);

ALTER TABLE public.t_predefined_analysis_scheduling_queue CLUSTER ON pk_t_predefined_analysis_scheduling_queue;

--
-- Name: ix_t_predefined_analysis_scheduling_queue_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_predefined_analysis_scheduling_queue_dataset_id ON public.t_predefined_analysis_scheduling_queue USING btree (dataset_id);

--
-- Name: ix_t_predefined_analysis_scheduling_queue_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_predefined_analysis_scheduling_queue_state ON public.t_predefined_analysis_scheduling_queue USING btree (state);

--
-- Name: t_predefined_analysis_scheduling_queue trig_t_predefined_analysis_scheduling_queue_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_predefined_analysis_scheduling_queue_after_update AFTER UPDATE ON public.t_predefined_analysis_scheduling_queue FOR EACH ROW WHEN ((old.state OPERATOR(public.<>) new.state)) EXECUTE FUNCTION public.trigfn_t_predefined_analysis_scheduling_queue_after_update();

--
-- Name: t_predefined_analysis_scheduling_queue fk_t_predefined_analysis_scheduling_queue_t_predefined; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis_scheduling_queue
    ADD CONSTRAINT fk_t_predefined_analysis_scheduling_queue_t_predefined FOREIGN KEY (state) REFERENCES public.t_predefined_analysis_scheduling_queue_state(state);

--
-- Name: TABLE t_predefined_analysis_scheduling_queue; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_queue TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_predefined_analysis_scheduling_queue TO writeaccess;

