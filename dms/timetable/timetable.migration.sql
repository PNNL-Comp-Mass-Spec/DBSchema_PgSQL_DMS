--
-- Name: migration; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE TABLE timetable.migration (
    id bigint NOT NULL,
    version text NOT NULL
);


ALTER TABLE timetable.migration OWNER TO d3l243;

--
-- Name: migration migration_pkey; Type: CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.migration
    ADD CONSTRAINT migration_pkey PRIMARY KEY (id);

--
-- Name: TABLE migration; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.migration TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.migration TO "svc-dms";

