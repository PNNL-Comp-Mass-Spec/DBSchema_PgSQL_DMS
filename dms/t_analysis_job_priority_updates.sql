--
-- Name: t_analysis_job_priority_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_priority_updates (
    entry_id integer NOT NULL,
    job integer NOT NULL,
    old_priority smallint NOT NULL,
    new_priority smallint NOT NULL,
    comment public.citext,
    entered timestamp without time zone NOT NULL
);


ALTER TABLE public.t_analysis_job_priority_updates OWNER TO d3l243;

--
-- Name: t_analysis_job_priority_updates_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_analysis_job_priority_updates ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_analysis_job_priority_updates_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_analysis_job_priority_updates pk_t_analysis_job_priority_updates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_priority_updates
    ADD CONSTRAINT pk_t_analysis_job_priority_updates PRIMARY KEY (entry_id);

--
-- Name: ix_t_analysis_job_priority_updates_job; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_priority_updates_job ON public.t_analysis_job_priority_updates USING btree (job);

--
-- Name: TABLE t_analysis_job_priority_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_priority_updates TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_analysis_job_priority_updates TO writeaccess;

