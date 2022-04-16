--
-- Name: t_filter_set_criteria_name_tool_map; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_criteria_name_tool_map (
    criterion_id integer NOT NULL,
    analysis_tool_id integer NOT NULL
);


ALTER TABLE public.t_filter_set_criteria_name_tool_map OWNER TO d3l243;

--
-- Name: TABLE t_filter_set_criteria_name_tool_map; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_criteria_name_tool_map TO readaccess;

