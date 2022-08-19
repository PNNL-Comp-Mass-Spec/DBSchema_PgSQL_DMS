--
-- Name: t_capture_task_stats; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_capture_task_stats (
    script public.citext NOT NULL,
    instrument public.citext NOT NULL,
    year integer NOT NULL,
    jobs integer NOT NULL
);


ALTER TABLE cap.t_capture_task_stats OWNER TO d3l243;

--
-- Name: t_capture_task_stats pk_t_capture_task_stats; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_capture_task_stats
    ADD CONSTRAINT pk_t_capture_task_stats PRIMARY KEY (script, instrument, year);

--
-- Name: TABLE t_capture_task_stats; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_capture_task_stats TO readaccess;

