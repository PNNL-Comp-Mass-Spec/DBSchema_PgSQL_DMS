--
-- Name: t_analysis_job_processors; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processors (
    processor_id integer NOT NULL,
    state character(1) NOT NULL,
    processor_name public.citext NOT NULL,
    machine public.citext NOT NULL,
    notes public.citext,
    last_affected timestamp without time zone,
    entered_by public.citext
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
-- Name: t_analysis_job_processors pk_t_analysis_job_processors; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processors
    ADD CONSTRAINT pk_t_analysis_job_processors PRIMARY KEY (processor_id);

--
-- Name: ix_t_analysis_job_processors_id_name_state_machine; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_processors_id_name_state_machine ON public.t_analysis_job_processors USING btree (processor_id, processor_name) INCLUDE (state, machine);

--
-- Name: TABLE t_analysis_job_processors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processors TO readaccess;

