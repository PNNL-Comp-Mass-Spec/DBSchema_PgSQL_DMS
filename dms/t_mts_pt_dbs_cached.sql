--
-- Name: t_mts_pt_dbs_cached; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mts_pt_dbs_cached (
    peptide_db_id integer NOT NULL,
    server_name public.citext NOT NULL,
    peptide_db_name public.citext NOT NULL,
    state_id integer NOT NULL,
    state public.citext NOT NULL,
    description public.citext,
    organism public.citext,
    last_affected timestamp without time zone NOT NULL,
    msms_jobs integer,
    sic_jobs integer
);


ALTER TABLE public.t_mts_pt_dbs_cached OWNER TO d3l243;

--
-- Name: t_mts_pt_dbs_cached pk_t_mts_pt_dbs_cached_dbid; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mts_pt_dbs_cached
    ADD CONSTRAINT pk_t_mts_pt_dbs_cached_dbid PRIMARY KEY (peptide_db_id);

--
-- Name: ix_t_mts_pt_dbs_cached_dbname; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_pt_dbs_cached_dbname ON public.t_mts_pt_dbs_cached USING btree (peptide_db_name);

--
-- Name: ix_t_mts_pt_dbs_cached_server_dbname; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_pt_dbs_cached_server_dbname ON public.t_mts_pt_dbs_cached USING btree (server_name, peptide_db_name);

--
-- Name: ix_t_mts_pt_dbs_cached_state_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_pt_dbs_cached_state_name ON public.t_mts_pt_dbs_cached USING btree (state);

--
-- Name: TABLE t_mts_pt_dbs_cached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_pt_dbs_cached TO readaccess;
GRANT SELECT ON TABLE public.t_mts_pt_dbs_cached TO writeaccess;

