--
-- Name: t_analysis_job_processors; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processors (
    processor_id integer NOT NULL,
    state character(1) DEFAULT 'E'::bpchar NOT NULL,
    processor_name public.citext NOT NULL,
    machine public.citext NOT NULL,
    notes public.citext DEFAULT ''::public.citext,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER,
    CONSTRAINT ck_t_analysis_job_processors_state CHECK (((state = 'D'::bpchar) OR (state = 'E'::bpchar)))
);


ALTER TABLE public.t_analysis_job_processors OWNER TO d3l243;

--
-- Name: t_analysis_job_processors_processor_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_analysis_job_processors ALTER COLUMN processor_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_analysis_job_processors_processor_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_analysis_job_processors ix_t_analysis_job_processors_unique_processor_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processors
    ADD CONSTRAINT ix_t_analysis_job_processors_unique_processor_name UNIQUE (processor_name);

--
-- Name: t_analysis_job_processors pk_t_analysis_job_processors; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processors
    ADD CONSTRAINT pk_t_analysis_job_processors PRIMARY KEY (processor_id);

--
-- Name: ix_t_analysis_job_processors_id_name_state_machine; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_processors_id_name_state_machine ON public.t_analysis_job_processors USING btree (processor_id, processor_name) INCLUDE (state, machine);

--
-- Name: t_analysis_job_processors trig_t_analysis_job_processors_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_analysis_job_processors_after_update AFTER UPDATE ON public.t_analysis_job_processors REFERENCING OLD TABLE AS old NEW TABLE AS new FOR EACH ROW EXECUTE FUNCTION public.trigfn_t_analysis_job_processors_after_update();

--
-- Name: TABLE t_analysis_job_processors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processors TO readaccess;

