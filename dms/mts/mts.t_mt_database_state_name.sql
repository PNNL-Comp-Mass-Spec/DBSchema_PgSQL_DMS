--
-- Name: t_mt_database_state_name; Type: TABLE; Schema: mts; Owner: d3l243
--

CREATE TABLE mts.t_mt_database_state_name (
    state_id integer NOT NULL,
    state_name public.citext
);


ALTER TABLE mts.t_mt_database_state_name OWNER TO d3l243;

--
-- Name: t_mt_database_state_name pk_t_mt_database_state_name; Type: CONSTRAINT; Schema: mts; Owner: d3l243
--

ALTER TABLE ONLY mts.t_mt_database_state_name
    ADD CONSTRAINT pk_t_mt_database_state_name PRIMARY KEY (state_id);

--
-- Name: ix_t_mt_database_state_name_state_name; Type: INDEX; Schema: mts; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_mt_database_state_name_state_name ON mts.t_mt_database_state_name USING btree (state_name);

