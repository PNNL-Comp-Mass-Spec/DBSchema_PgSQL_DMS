--
-- Name: v_job_step_processing_log_retries; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_processing_log_retries AS
 SELECT jsl.event_id,
    jsl.job,
    jsl.step,
    jsl.processor,
    jsl.remote_info_id,
    jsl.entered,
    jsl.entered_by
   FROM (sw.t_job_step_processing_log jsl
     JOIN ( SELECT t_job_step_processing_log.job,
            t_job_step_processing_log.step
           FROM sw.t_job_step_processing_log
          WHERE (t_job_step_processing_log.entered >= (CURRENT_TIMESTAMP - '7 days'::interval))
          GROUP BY t_job_step_processing_log.job, t_job_step_processing_log.step
         HAVING (count(*) > 1)) filterq ON (((jsl.job = filterq.job) AND (jsl.step = filterq.step))));


ALTER VIEW sw.v_job_step_processing_log_retries OWNER TO d3l243;

--
-- Name: VIEW v_job_step_processing_log_retries; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_job_step_processing_log_retries IS 'Job steps started within the last week where the step was reset at least once';

--
-- Name: TABLE v_job_step_processing_log_retries; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_processing_log_retries TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_processing_log_retries TO writeaccess;

