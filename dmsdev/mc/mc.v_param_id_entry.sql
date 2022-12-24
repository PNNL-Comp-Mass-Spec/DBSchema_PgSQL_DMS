--
-- Name: v_param_id_entry; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_param_id_entry AS
 SELECT t_param_type.param_id,
    t_param_type.param_name,
    t_param_type.picklist_name,
    t_param_type.comment
   FROM mc.t_param_type;


ALTER TABLE mc.v_param_id_entry OWNER TO d3l243;

