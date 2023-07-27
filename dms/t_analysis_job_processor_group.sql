--
-- Name: t_analysis_job_processor_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_group (
    group_id integer NOT NULL,
    group_name public.citext NOT NULL,
    group_description public.citext,
    group_enabled public.citext DEFAULT 'Y'::bpchar NOT NULL,
    group_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_analysis_job_processor_group OWNER TO d3l243;

--
-- Name: t_analysis_job_processor_group_group_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_analysis_job_processor_group ALTER COLUMN group_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_analysis_job_processor_group_group_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_analysis_job_processor_group ix_t_analysis_job_processor_group_unique_group_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group
    ADD CONSTRAINT ix_t_analysis_job_processor_group_unique_group_name UNIQUE (group_name);

--
-- Name: t_analysis_job_processor_group pk_t_analysis_job_processor_group; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group
    ADD CONSTRAINT pk_t_analysis_job_processor_group PRIMARY KEY (group_id);

--
-- Name: t_analysis_job_processor_group trig_t_analysis_job_processor_group_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_analysis_job_processor_group_after_update AFTER UPDATE ON public.t_analysis_job_processor_group FOR EACH ROW WHEN (((old.group_name OPERATOR(public.<>) new.group_name) OR (old.group_enabled OPERATOR(public.<>) new.group_enabled))) EXECUTE FUNCTION public.trigfn_t_analysis_job_processor_group_after_update();

--
-- Name: TABLE t_analysis_job_processor_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_group TO readaccess;
GRANT SELECT ON TABLE public.t_analysis_job_processor_group TO writeaccess;

