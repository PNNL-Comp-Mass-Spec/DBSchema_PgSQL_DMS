--
-- Name: t_task_step_state_name; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_step_state_name (
    step_state_id smallint NOT NULL,
    step_state public.citext NOT NULL,
    description public.citext
);


ALTER TABLE cap.t_task_step_state_name OWNER TO d3l243;

--
-- Name: t_task_step_state_name pk_t_step_state; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_step_state_name
    ADD CONSTRAINT pk_t_step_state PRIMARY KEY (step_state_id);

--
-- Name: TABLE t_task_step_state_name; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_step_state_name TO readaccess;
GRANT SELECT ON TABLE cap.t_task_step_state_name TO writeaccess;

