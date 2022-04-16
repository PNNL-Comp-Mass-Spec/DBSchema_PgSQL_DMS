--
-- Name: t_data_analysis_request_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request_type_name (
    analysis_type public.citext NOT NULL
);


ALTER TABLE public.t_data_analysis_request_type_name OWNER TO d3l243;

--
-- Name: TABLE t_data_analysis_request_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request_type_name TO readaccess;

