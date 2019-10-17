--
-- Name: v_managers_by_broadcast_queue_topic; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_managers_by_broadcast_queue_topic AS
 SELECT t_mgrs.m_name AS mgrname,
    t_mgr_types.mt_type_name AS mgrtype,
    tb.broadcastqueuetopic AS broadcasttopic,
    tm.messagequeueuri AS msgqueueuri
   FROM (((mc.t_mgrs
     JOIN ( SELECT pv1.mgr_id,
            pv1.value AS broadcastqueuetopic
           FROM mc.t_param_value pv1
          WHERE (pv1.type_id = 117)) tb ON ((t_mgrs.m_id = tb.mgr_id)))
     JOIN mc.t_mgr_types ON ((t_mgrs.m_type_id = t_mgr_types.mt_type_id)))
     JOIN ( SELECT pv2.mgr_id,
            (pv2.value)::character varying(128) AS messagequeueuri
           FROM mc.t_param_value pv2
          WHERE (pv2.type_id = 105)) tm ON ((t_mgrs.m_id = tm.mgr_id)));


ALTER TABLE mc.v_managers_by_broadcast_queue_topic OWNER TO d3l243;

--
-- Name: TABLE v_managers_by_broadcast_queue_topic; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_managers_by_broadcast_queue_topic TO readaccess;
