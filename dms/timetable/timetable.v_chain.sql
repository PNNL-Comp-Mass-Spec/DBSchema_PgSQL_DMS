--
-- Name: v_chain; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain AS
 SELECT c.chain_id,
    c.chain_name,
    c.run_at,
    c.live,
    i.interval_description,
    c.max_instances,
    c.timeout,
    c.self_destruct,
    c.exclusive_execution
   FROM (timetable.chain c
     LEFT JOIN timetable.t_cron_interval i ON (((c.run_at)::text = (i.cron_interval)::text)))
  ORDER BY c.chain_name;


ALTER VIEW timetable.v_chain OWNER TO d3l243;

