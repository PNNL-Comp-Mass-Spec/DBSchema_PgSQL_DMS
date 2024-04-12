--
-- Name: t_cron_interval; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE TABLE timetable.t_cron_interval (
    interval_id integer NOT NULL,
    cron_interval timetable.cron NOT NULL,
    interval_description public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE timetable.t_cron_interval OWNER TO d3l243;

--
-- Name: t_cron_interval_interval_id_seq; Type: SEQUENCE; Schema: timetable; Owner: d3l243
--

ALTER TABLE timetable.t_cron_interval ALTER COLUMN interval_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME timetable.t_cron_interval_interval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cron_interval pk_t_cron_interval; Type: CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.t_cron_interval
    ADD CONSTRAINT pk_t_cron_interval PRIMARY KEY (interval_id);

--
-- Name: ix_t_cron_interval_cron_interval; Type: INDEX; Schema: timetable; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_cron_interval_cron_interval ON timetable.t_cron_interval USING btree (cron_interval);

--
-- Name: TABLE t_cron_interval; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.t_cron_interval TO readaccess;
GRANT SELECT ON TABLE timetable.t_cron_interval TO writeaccess;

