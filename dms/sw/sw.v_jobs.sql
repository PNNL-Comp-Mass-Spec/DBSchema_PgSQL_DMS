--
-- Name: v_jobs; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_jobs AS
 SELECT j.job,
    j.priority,
    j.script,
    j.state,
    jsn.job_state,
    j.dataset,
    j.dataset_id,
    j.results_folder_name,
    j.organism_db_name,
    j.imported,
    j.start,
    j.finish,
    j.archive_busy,
    j.transfer_folder_path,
    j.owner_username AS owner,
    j.data_pkg_id,
    j.comment,
    j.storage_server,
    j.special_processing
   FROM (sw.t_job_state_name jsn
     JOIN sw.t_jobs j ON ((j.state = jsn.job_state_id)));


ALTER TABLE sw.v_jobs OWNER TO d3l243;

--
-- Name: v_jobs trig_v_jobs_instead_of_update; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_v_jobs_instead_of_update INSTEAD OF UPDATE ON sw.v_jobs FOR EACH ROW EXECUTE FUNCTION sw.trigfn_v_jobs_instead_of_update();

--
-- Name: TABLE v_jobs; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_jobs TO readaccess;
GRANT SELECT ON TABLE sw.v_jobs TO writeaccess;

