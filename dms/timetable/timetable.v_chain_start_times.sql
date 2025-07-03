--
-- Name: v_chain_start_times; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain_start_times AS
 SELECT leadq.chain_id,
    leadq.start_time,
    leadq.next_start_time,
    ((leadq.next_start_time - leadq.start_time))::interval minute AS start_delta,
    c.run_at,
    i.interval_description
   FROM ((( SELECT el.last_run AS start_time,
            el.chain_id,
            el.task_id,
            lead(el.last_run, 1) OVER (PARTITION BY el.chain_id ORDER BY el.last_run) AS next_start_time
           FROM (timetable.execution_log el
             JOIN ( SELECT el_1.chain_id,
                    min(el_1.task_id) AS task_id_min
                   FROM timetable.execution_log el_1
                  GROUP BY el_1.chain_id) groupq ON (((el.chain_id = groupq.chain_id) AND (el.task_id = groupq.task_id_min))))) leadq
     JOIN timetable.chain c ON ((leadq.chain_id = c.chain_id)))
     LEFT JOIN timetable.t_cron_interval i ON (((c.run_at)::text = (i.cron_interval)::text)));


ALTER VIEW timetable.v_chain_start_times OWNER TO d3l243;

--
-- Name: TABLE v_chain_start_times; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.v_chain_start_times TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.v_chain_start_times TO pgdms;

