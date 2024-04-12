--
-- Name: t_task_parameters; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_parameters (
    job integer NOT NULL,
    parameters xml
);


ALTER TABLE cap.t_task_parameters OWNER TO d3l243;

--
-- Name: t_task_parameters pk_t_task_parameters; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_parameters
    ADD CONSTRAINT pk_t_task_parameters PRIMARY KEY (job);

--
-- Name: t_task_parameters fk_t_task_parameters_t_tasks; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_parameters
    ADD CONSTRAINT fk_t_task_parameters_t_tasks FOREIGN KEY (job) REFERENCES cap.t_tasks(job) ON DELETE CASCADE;

--
-- Name: TABLE t_task_parameters; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_parameters TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_task_parameters TO writeaccess;

