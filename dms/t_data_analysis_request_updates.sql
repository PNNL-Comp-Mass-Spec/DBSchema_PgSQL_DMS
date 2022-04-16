--
-- Name: t_data_analysis_request_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request_updates (
    id integer NOT NULL,
    request_id integer NOT NULL,
    old_state_id smallint NOT NULL,
    new_state_id smallint NOT NULL,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext NOT NULL
);


ALTER TABLE public.t_data_analysis_request_updates OWNER TO d3l243;

--
-- Name: TABLE t_data_analysis_request_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request_updates TO readaccess;

