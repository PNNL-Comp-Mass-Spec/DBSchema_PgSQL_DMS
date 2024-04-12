--
-- Name: v_param_id_entry; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_param_id_entry AS
 SELECT param_type_id AS param_id,
    param_name,
    picklist_name,
    comment
   FROM mc.t_param_type;


ALTER VIEW mc.v_param_id_entry OWNER TO d3l243;

--
-- Name: TABLE v_param_id_entry; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_param_id_entry TO readaccess;
GRANT SELECT ON TABLE mc.v_param_id_entry TO writeaccess;

