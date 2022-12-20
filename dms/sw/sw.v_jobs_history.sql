--
-- Name: v_jobs_history; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_jobs_history AS
 SELECT jh.job,
    jh.priority,
    jh.script,
    jh.state,
    jsn.job_state,
    jh.dataset,
    jh.dataset_id,
    jh.results_folder_name,
    jh.organism_db_name,
    jh.imported,
    jh.start,
    jh.finish,
    jh.runtime_minutes,
    jh.saved,
    jh.most_recent_entry,
    jh.transfer_folder_path,
    jh.owner,
    jh.data_pkg_id,
    jh.comment,
    jh.special_processing
   FROM (sw.t_job_state_name jsn
     JOIN sw.t_jobs_history jh ON ((jh.state = jsn.job_state_id)));


ALTER TABLE sw.v_jobs_history OWNER TO d3l243;

--
-- Name: TABLE v_jobs_history; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_jobs_history TO readaccess;
GRANT SELECT ON TABLE sw.v_jobs_history TO writeaccess;

