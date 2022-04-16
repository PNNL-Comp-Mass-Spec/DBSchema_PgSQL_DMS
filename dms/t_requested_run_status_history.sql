--
-- Name: t_requested_run_status_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_status_history (
    entry_id integer NOT NULL,
    posting_time timestamp without time zone NOT NULL,
    state_id smallint NOT NULL,
    origin public.citext NOT NULL,
    request_count integer NOT NULL,
    queue_time_0days integer,
    queue_time_1to6days integer,
    queue_time_7to44days integer,
    queue_time_45to89days integer,
    queue_time_90to179days integer,
    queue_time_180days_and_up integer
);


ALTER TABLE public.t_requested_run_status_history OWNER TO d3l243;

--
-- Name: TABLE t_requested_run_status_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_status_history TO readaccess;

