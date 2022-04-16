--
-- Name: t_data_analysis_request_batch_ids; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request_batch_ids (
    request_id integer NOT NULL,
    batch_id integer NOT NULL
);


ALTER TABLE public.t_data_analysis_request_batch_ids OWNER TO d3l243;

--
-- Name: TABLE t_data_analysis_request_batch_ids; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request_batch_ids TO readaccess;

