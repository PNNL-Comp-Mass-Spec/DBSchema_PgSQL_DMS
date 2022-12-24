--
-- Name: v_manager_entry; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_entry AS
 SELECT t_mgrs.mgr_id AS managerid,
    t_mgrs.mgr_name AS managername,
    t_mgrs.control_from_website AS controlfromwebsite
   FROM mc.t_mgrs;


ALTER TABLE mc.v_manager_entry OWNER TO d3l243;

