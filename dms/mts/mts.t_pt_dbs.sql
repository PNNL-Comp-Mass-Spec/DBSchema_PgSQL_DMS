--
-- Name: t_pt_dbs; Type: TABLE; Schema: mts; Owner: d3l243
--

CREATE TABLE mts.t_pt_dbs (
    peptide_db_id integer NOT NULL,
    peptide_db_name public.citext NOT NULL,
    server_id integer NOT NULL,
    state_id integer NOT NULL,
    last_affected timestamp without time zone NOT NULL,
    description public.citext,
    organism public.citext,
    db_schema_version integer NOT NULL,
    comment text,
    created timestamp without time zone,
    last_online date
);


ALTER TABLE mts.t_pt_dbs OWNER TO d3l243;

--
-- Name: t_pt_dbs pk_t_pt_dbs; Type: CONSTRAINT; Schema: mts; Owner: d3l243
--

ALTER TABLE ONLY mts.t_pt_dbs
    ADD CONSTRAINT pk_t_pt_dbs PRIMARY KEY (peptide_db_id);

--
-- Name: ix_t_pt_dbs_peptide_db_name; Type: INDEX; Schema: mts; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_pt_dbs_peptide_db_name ON mts.t_pt_dbs USING btree (peptide_db_name);

