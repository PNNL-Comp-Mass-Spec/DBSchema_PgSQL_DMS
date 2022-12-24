--
-- Name: v_analysis_job_processors_list_report; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_analysis_job_processors_list_report AS
 SELECT m.mgr_id AS id,
    m.mgr_name AS name,
    mt.mgr_type_name AS type
   FROM (mc.t_mgrs m
     JOIN mc.t_mgr_types mt ON ((m.mgr_type_id = mt.mgr_type_id)));


ALTER TABLE mc.v_analysis_job_processors_list_report OWNER TO d3l243;

