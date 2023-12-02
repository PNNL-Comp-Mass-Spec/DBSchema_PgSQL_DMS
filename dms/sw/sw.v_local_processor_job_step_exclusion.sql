--
-- Name: v_local_processor_job_step_exclusion; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_local_processor_job_step_exclusion AS
 SELECT lp.processor_name,
    lp.processor_id,
    jse.step
   FROM (sw.t_local_processor_job_step_exclusion jse
     JOIN sw.t_local_processors lp ON ((jse.processor_id = lp.processor_id)));


ALTER VIEW sw.v_local_processor_job_step_exclusion OWNER TO d3l243;

--
-- Name: TABLE v_local_processor_job_step_exclusion; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_local_processor_job_step_exclusion TO readaccess;
GRANT SELECT ON TABLE sw.v_local_processor_job_step_exclusion TO writeaccess;

