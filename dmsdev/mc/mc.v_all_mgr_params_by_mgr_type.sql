--
-- Name: v_all_mgr_params_by_mgr_type; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_all_mgr_params_by_mgr_type AS
 SELECT DISTINCT tpt.mgr_type_id AS id,
        CASE
            WHEN (mtpm.mgr_type_id IS NOT NULL) THEN 'TRUE'::text
            ELSE ''::text
        END AS selected,
    tpt.param_id,
    tpt.param_name,
    tpt.comment
   FROM (( SELECT DISTINCT t_param_type.param_id,
            t_param_type.param_name,
            t_param_type.comment,
            t_mgr_types.mgr_type_id,
            t_mgr_types.mgr_type_name
           FROM mc.t_param_type,
            mc.t_mgr_types) tpt
     LEFT JOIN mc.t_mgr_type_param_type_map mtpm ON (((tpt.param_id = mtpm.param_type_id) AND (tpt.mgr_type_id = mtpm.mgr_type_id))));


ALTER TABLE mc.v_all_mgr_params_by_mgr_type OWNER TO d3l243;

