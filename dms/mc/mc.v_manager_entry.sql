--
-- Name: v_manager_entry; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_entry AS
 SELECT t_mgrs.mgr_id AS manager_id,
    t_mgrs.mgr_name AS manager_name,
    t_mgrs.control_from_website
   FROM mc.t_mgrs;


ALTER TABLE mc.v_manager_entry OWNER TO d3l243;

--
-- Name: TABLE v_manager_entry; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_entry TO readaccess;
GRANT SELECT ON TABLE mc.v_manager_entry TO writeaccess;

