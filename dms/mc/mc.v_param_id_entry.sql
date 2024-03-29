--
-- Name: v_param_id_entry; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_param_id_entry AS
 SELECT t_param_type.param_type_id AS param_id,
    t_param_type.param_name,
    t_param_type.picklist_name,
    t_param_type.comment
   FROM mc.t_param_type;


ALTER VIEW mc.v_param_id_entry OWNER TO d3l243;

--
-- Name: TABLE v_param_id_entry; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_param_id_entry TO readaccess;
GRANT SELECT ON TABLE mc.v_param_id_entry TO writeaccess;

