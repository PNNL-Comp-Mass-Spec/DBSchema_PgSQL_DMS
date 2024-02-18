--
-- Name: t_mts_servers; Type: TABLE; Schema: mts; Owner: d3l243
--

CREATE TABLE mts.t_mts_servers (
    server_id integer NOT NULL,
    server_name public.citext NOT NULL,
    active smallint
);


ALTER TABLE mts.t_mts_servers OWNER TO d3l243;

--
-- Name: t_mts_servers pk_t_mts_servers; Type: CONSTRAINT; Schema: mts; Owner: d3l243
--

ALTER TABLE ONLY mts.t_mts_servers
    ADD CONSTRAINT pk_t_mts_servers PRIMARY KEY (server_id);

--
-- Name: ix_t_mts_servers_server_name; Type: INDEX; Schema: mts; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_mts_servers_server_name ON mts.t_mts_servers USING btree (server_name);

--
-- Name: TABLE t_mts_servers; Type: ACL; Schema: mts; Owner: d3l243
--

GRANT SELECT ON TABLE mts.t_mts_servers TO readaccess;
GRANT SELECT ON TABLE mts.t_mts_servers TO writeaccess;

