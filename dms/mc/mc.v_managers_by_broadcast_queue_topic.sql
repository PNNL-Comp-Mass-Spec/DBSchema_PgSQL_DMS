--
-- Name: v_managers_by_broadcast_queue_topic; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_managers_by_broadcast_queue_topic AS
 SELECT m.mgr_name,
    mt.mgr_type_name AS mgr_type,
    tb.broadcastqueuetopic AS broadcast_topic,
    tm.messagequeueuri AS msg_queue_uri
   FROM (((mc.t_mgrs m
     JOIN ( SELECT pv.mgr_id,
            pv.value AS broadcastqueuetopic
           FROM mc.t_param_value pv
          WHERE (pv.param_type_id = 117)) tb ON ((m.mgr_id = tb.mgr_id)))
     JOIN mc.t_mgr_types mt ON ((m.mgr_type_id = mt.mgr_type_id)))
     JOIN ( SELECT pv.mgr_id,
            (pv.value)::character varying(128) AS messagequeueuri
           FROM mc.t_param_value pv
          WHERE (pv.param_type_id = 105)) tm ON ((m.mgr_id = tm.mgr_id)));


ALTER VIEW mc.v_managers_by_broadcast_queue_topic OWNER TO d3l243;

--
-- Name: TABLE v_managers_by_broadcast_queue_topic; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_managers_by_broadcast_queue_topic TO readaccess;
GRANT SELECT ON TABLE mc.v_managers_by_broadcast_queue_topic TO writeaccess;

