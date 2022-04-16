--
-- Name: t_analysis_tool_allowed_dataset_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_tool_allowed_dataset_type (
    analysis_tool_id integer NOT NULL,
    dataset_type public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_analysis_tool_allowed_dataset_type OWNER TO d3l243;

--
-- Name: TABLE t_analysis_tool_allowed_dataset_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_tool_allowed_dataset_type TO readaccess;

