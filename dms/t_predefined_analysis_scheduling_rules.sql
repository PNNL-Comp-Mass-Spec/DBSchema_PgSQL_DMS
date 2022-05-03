--
-- Name: t_predefined_analysis_scheduling_rules; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_rules (
    rule_id integer NOT NULL,
    evaluation_order smallint NOT NULL,
    instrument_class public.citext NOT NULL,
    instrument_name public.citext NOT NULL,
    dataset_name public.citext NOT NULL,
    analysis_tool_name public.citext NOT NULL,
    priority integer NOT NULL,
    processor_group_id integer,
    enabled smallint NOT NULL,
    created timestamp without time zone NOT NULL
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
-- Name: TABLE t_predefined_analysis_scheduling_rules; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_rules TO readaccess;

