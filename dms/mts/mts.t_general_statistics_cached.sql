--
-- Name: t_general_statistics_cached; Type: TABLE; Schema: mts; Owner: d3l243
--

CREATE TABLE mts.t_general_statistics_cached (
    server_name public.citext NOT NULL,
    db_name public.citext NOT NULL,
    category public.citext,
    label public.citext,
    value public.citext,
    entry_id integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE mts.t_general_statistics_cached OWNER TO d3l243;

--
-- Name: t_general_statistics_cached pk_t_general_statistics_cached; Type: CONSTRAINT; Schema: mts; Owner: d3l243
--

ALTER TABLE ONLY mts.t_general_statistics_cached
    ADD CONSTRAINT pk_t_general_statistics_cached PRIMARY KEY (server_name, db_name, entry_id);

ALTER TABLE mts.t_general_statistics_cached CLUSTER ON pk_t_general_statistics_cached;

--
-- Name: TABLE t_general_statistics_cached; Type: ACL; Schema: mts; Owner: d3l243
--

GRANT SELECT ON TABLE mts.t_general_statistics_cached TO readaccess;
GRANT SELECT ON TABLE mts.t_general_statistics_cached TO writeaccess;

