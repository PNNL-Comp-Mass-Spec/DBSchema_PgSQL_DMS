--
-- Name: parameter; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE TABLE timetable.parameter (
    task_id bigint NOT NULL,
    order_id integer NOT NULL,
    value jsonb,
    CONSTRAINT parameter_order_id_check CHECK ((order_id > 0))
);


ALTER TABLE timetable.parameter OWNER TO d3l243;

--
-- Name: TABLE parameter; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON TABLE timetable.parameter IS 'Stores parameters passed as arguments to a chain task';

--
-- Name: parameter parameter_pkey; Type: CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.parameter
    ADD CONSTRAINT parameter_pkey PRIMARY KEY (task_id, order_id);

--
-- Name: parameter parameter_task_id_fkey; Type: FK CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.parameter
    ADD CONSTRAINT parameter_task_id_fkey FOREIGN KEY (task_id) REFERENCES timetable.task(task_id) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: TABLE parameter; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.parameter TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.parameter TO "svc-dms";

