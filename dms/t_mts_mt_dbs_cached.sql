--
-- Name: t_mts_mt_dbs_cached; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mts_mt_dbs_cached (
    mt_db_id integer NOT NULL,
    server_name public.citext NOT NULL,
    mt_db_name public.citext NOT NULL,
    state_id integer NOT NULL,
    state public.citext,
    description public.citext,
    organism public.citext,
    campaign public.citext,
    peptide_db public.citext,
    peptide_db_count smallint,
    last_affected timestamp without time zone NOT NULL,
    msms_jobs integer,
    ms_jobs integer
);


ALTER TABLE public.t_mts_mt_dbs_cached OWNER TO d3l243;

--
-- Name: t_mts_mt_dbs_cached pk_t_mts_mt_dbs_cached; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mts_mt_dbs_cached
    ADD CONSTRAINT pk_t_mts_mt_dbs_cached PRIMARY KEY (mt_db_id);

ALTER TABLE public.t_mts_mt_dbs_cached CLUSTER ON pk_t_mts_mt_dbs_cached;

--
-- Name: ix_t_mts_mt_dbs_cached_dbname; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_mt_dbs_cached_dbname ON public.t_mts_mt_dbs_cached USING btree (mt_db_name);

--
-- Name: ix_t_mts_mt_dbs_cached_server_dbname; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_mt_dbs_cached_server_dbname ON public.t_mts_mt_dbs_cached USING btree (server_name, mt_db_name);

--
-- Name: ix_t_mts_mt_dbs_cached_state_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_mt_dbs_cached_state_name ON public.t_mts_mt_dbs_cached USING btree (state);

--
-- Name: TABLE t_mts_mt_dbs_cached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_mt_dbs_cached TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_mts_mt_dbs_cached TO writeaccess;

