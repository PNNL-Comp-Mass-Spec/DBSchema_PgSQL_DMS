--
-- Name: v_active_chain; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_active_chain AS
 SELECT activechains.chain_id,
    activechains.client_name,
    activechains.started_at,
    chaininfo.chain_name,
    chaininfo.run_at,
    chaininfo.live,
    chaininfo.interval_description,
    chaininfo.max_instances,
    chaininfo.timeout_msec,
    chaininfo.self_destruct,
    chaininfo.exclusive_execution
   FROM (timetable.active_chain activechains
     JOIN timetable.v_chain chaininfo ON ((activechains.chain_id = chaininfo.chain_id)));


ALTER VIEW timetable.v_active_chain OWNER TO d3l243;

--
-- Name: TABLE v_active_chain; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.v_active_chain TO writeaccess;

