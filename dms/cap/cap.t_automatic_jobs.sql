--
-- Name: t_automatic_jobs; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_automatic_jobs (
    script_for_completed_job public.citext NOT NULL,
    script_for_new_job public.citext NOT NULL,
    enabled smallint DEFAULT 1 NOT NULL
);


ALTER TABLE cap.t_automatic_jobs OWNER TO d3l243;

--
-- Name: t_automatic_jobs pk_t_automatic_jobs; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_automatic_jobs
    ADD CONSTRAINT pk_t_automatic_jobs PRIMARY KEY (script_for_completed_job, script_for_new_job);

ALTER TABLE cap.t_automatic_jobs CLUSTER ON pk_t_automatic_jobs;

--
-- Name: t_automatic_jobs fk_t_automatic_jobs_t_scripts; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_automatic_jobs
    ADD CONSTRAINT fk_t_automatic_jobs_t_scripts FOREIGN KEY (script_for_completed_job) REFERENCES cap.t_scripts(script);

--
-- Name: t_automatic_jobs fk_t_automatic_jobs_t_scripts1; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_automatic_jobs
    ADD CONSTRAINT fk_t_automatic_jobs_t_scripts1 FOREIGN KEY (script_for_new_job) REFERENCES cap.t_scripts(script);

--
-- Name: TABLE t_automatic_jobs; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_automatic_jobs TO readaccess;
GRANT SELECT ON TABLE cap.t_automatic_jobs TO writeaccess;

