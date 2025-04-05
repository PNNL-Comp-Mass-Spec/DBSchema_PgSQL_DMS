--
-- Name: t_mt_dbs; Type: TABLE; Schema: mts; Owner: d3l243
--

CREATE TABLE mts.t_mt_dbs (
    mt_db_id integer NOT NULL,
    mt_db_name public.citext NOT NULL,
    server_id integer NOT NULL,
    state_id integer NOT NULL,
    last_affected timestamp without time zone NOT NULL,
    description public.citext,
    organism public.citext,
    campaign public.citext,
    db_schema_version real NOT NULL,
    comment public.citext,
    created timestamp without time zone,
    last_online date
);


ALTER TABLE mts.t_mt_dbs OWNER TO d3l243;

--
-- Name: t_mt_dbs pk_t_mt_dbs; Type: CONSTRAINT; Schema: mts; Owner: d3l243
--

ALTER TABLE ONLY mts.t_mt_dbs
    ADD CONSTRAINT pk_t_mt_dbs PRIMARY KEY (mt_db_id);

ALTER TABLE mts.t_mt_dbs CLUSTER ON pk_t_mt_dbs;

--
-- Name: ix_t_mt_dbs_mt_db_name; Type: INDEX; Schema: mts; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_mt_dbs_mt_db_name ON mts.t_mt_dbs USING btree (mt_db_name);

--
-- Name: TABLE t_mt_dbs; Type: ACL; Schema: mts; Owner: d3l243
--

GRANT SELECT ON TABLE mts.t_mt_dbs TO readaccess;
GRANT SELECT ON TABLE mts.t_mt_dbs TO writeaccess;

