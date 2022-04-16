--
-- Name: t_analysis_status_monitor_params; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_status_monitor_params (
    processor_id integer NOT NULL,
    status_file_name_path public.citext,
    check_box_state smallint NOT NULL,
    use_for_status_check smallint NOT NULL
);


ALTER TABLE public.t_analysis_status_monitor_params OWNER TO d3l243;

--
-- Name: TABLE t_analysis_status_monitor_params; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_status_monitor_params TO readaccess;

