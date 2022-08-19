--
-- Name: t_task_state_name; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_state_name (
    job_state_id integer NOT NULL,
    job_state public.citext
);


ALTER TABLE cap.t_task_state_name OWNER TO d3l243;

--
-- Name: t_task_state_name pk_t_task_state_name; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_state_name
    ADD CONSTRAINT pk_t_task_state_name PRIMARY KEY (job_state_id);

--
-- Name: TABLE t_task_state_name; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_state_name TO readaccess;

