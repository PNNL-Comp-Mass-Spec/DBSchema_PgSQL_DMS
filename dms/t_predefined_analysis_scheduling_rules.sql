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
-- Name: TABLE t_predefined_analysis_scheduling_rules; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_rules TO readaccess;

