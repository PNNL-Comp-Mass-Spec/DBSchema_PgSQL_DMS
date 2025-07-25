--
-- Name: v_task; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_task AS
 SELECT c.chain_id,
    t.task_id,
    t.task_order,
    t.task_name,
    t.kind,
    t.command,
    t.ignore_error,
    t.autonomous,
    t.timeout,
    c.chain_name,
    c.run_at,
    c.live,
    i.interval_description
   FROM ((timetable.chain c
     LEFT JOIN timetable.t_cron_interval i ON (((c.run_at)::text = (i.cron_interval)::text)))
     LEFT JOIN timetable.task t ON ((c.chain_id = t.chain_id)))
  ORDER BY c.chain_id, t.task_id;


ALTER VIEW timetable.v_task OWNER TO d3l243;

--
-- Name: TABLE v_task; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.v_task TO writeaccess;

