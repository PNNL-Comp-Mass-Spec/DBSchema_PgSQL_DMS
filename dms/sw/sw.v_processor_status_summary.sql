--
-- Name: v_processor_status_summary; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_status_summary AS
 SELECT machine,
    (
        CASE
            WHEN ((running = 0) AND (idle = 0) AND (errored = 0)) THEN 'Disabled'::text
            WHEN ((running = 0) AND (errored > 0)) THEN 'Idle, Errored'::text
            WHEN ((running > 0) AND (errored > 0)) THEN 'Running, Errored'::text
            WHEN (running = 0) THEN 'Idle'::text
            ELSE 'Running'::text
        END)::public.citext AS status,
    running,
    idle,
    errored,
    disabled
   FROM ( SELECT lp.machine,
            sum(
                CASE
                    WHEN (ps.mgr_status OPERATOR(public.=) 'running'::public.citext) THEN 1
                    ELSE 0
                END) AS running,
            sum(
                CASE
                    WHEN (ps.mgr_status OPERATOR(public.=) 'stopped'::public.citext) THEN 1
                    ELSE 0
                END) AS idle,
            sum(
                CASE
                    WHEN (ps.mgr_status OPERATOR(public.=) 'stopped error'::public.citext) THEN 1
                    ELSE 0
                END) AS errored,
            sum(
                CASE
                    WHEN (ps.mgr_status OPERATOR(public.~~) 'disabled%'::public.citext) THEN 1
                    ELSE 0
                END) AS disabled
           FROM (sw.t_processor_status ps
             LEFT JOIN sw.t_local_processors lp ON ((ps.processor_name OPERATOR(public.=) lp.processor_name)))
          WHERE (ps.monitor_processor <> 0)
          GROUP BY lp.machine) machineq;


ALTER VIEW sw.v_processor_status_summary OWNER TO d3l243;

--
-- Name: TABLE v_processor_status_summary; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_status_summary TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_status_summary TO writeaccess;

