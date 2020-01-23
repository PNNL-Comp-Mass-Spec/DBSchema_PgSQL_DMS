--
-- Name: v_managers_by_broadcast_queue_topic; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_managers_by_broadcast_queue_topic AS
 SELECT m.m_name AS mgrname,
    mt.mgr_type_name AS mgrtype,
    tb.broadcastqueuetopic AS broadcasttopic,
    tm.messagequeueuri AS msgqueueuri
   FROM (((mc.t_mgrs m
     JOIN ( SELECT pv.mgr_id,
            pv.value AS broadcastqueuetopic
           FROM mc.t_param_value pv
          WHERE (pv.type_id = 117)) tb ON ((m.m_id = tb.mgr_id)))
     JOIN mc.t_mgr_types mt ON ((m.mgr_type_id = mt.mgr_type_id)))
     JOIN ( SELECT pv.mgr_id,
            (pv.value)::character varying(128) AS messagequeueuri
           FROM mc.t_param_value pv
          WHERE (pv.type_id = 105)) tm ON ((m.m_id = tm.mgr_id)));


ALTER TABLE mc.v_managers_by_broadcast_queue_topic OWNER TO d3l243;

--
-- Name: TABLE v_managers_by_broadcast_queue_topic; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_managers_by_broadcast_queue_topic TO readaccess;
