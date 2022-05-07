--
-- Name: t_predefined_analysis_scheduling_rules; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_rules (
    rule_id integer NOT NULL,
    evaluation_order smallint NOT NULL,
    instrument_class public.citext DEFAULT ''::public.citext NOT NULL,
    instrument_name public.citext DEFAULT ''::public.citext NOT NULL,
    dataset_name public.citext DEFAULT ''::public.citext NOT NULL,
    analysis_tool_name public.citext DEFAULT ''::public.citext NOT NULL,
    priority integer DEFAULT 3 NOT NULL,
    processor_group_id integer,
    enabled smallint DEFAULT 1 NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_predefined_analysis_scheduling_rules OWNER TO d3l243;

--
-- Name: t_predefined_analysis_scheduling_rules_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_predefined_analysis_scheduling_rules ALTER COLUMN rule_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_predefined_analysis_scheduling_rules_rule_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_predefined_analysis_scheduling_rules pk_t_predefined_analysis_scheduling_rules; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis_scheduling_rules
    ADD CONSTRAINT pk_t_predefined_analysis_scheduling_rules PRIMARY KEY (rule_id);

--
-- Name: t_predefined_analysis_scheduling_rules fk_t_predefined_analysis_scheduling_rules_t_analysis_job; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_predefined_analysis_scheduling_rules
    ADD CONSTRAINT fk_t_predefined_analysis_scheduling_rules_t_analysis_job FOREIGN KEY (processor_group_id) REFERENCES public.t_analysis_job_processor_group(group_id);

--
-- Name: TABLE t_predefined_analysis_scheduling_rules; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_rules TO readaccess;

