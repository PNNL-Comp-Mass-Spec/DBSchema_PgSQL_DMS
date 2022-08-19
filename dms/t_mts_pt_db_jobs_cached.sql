--
-- Name: t_mts_pt_db_jobs_cached; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mts_pt_db_jobs_cached (
    cached_info_id integer NOT NULL,
    server_name public.citext NOT NULL,
    peptide_db_name public.citext NOT NULL,
    job integer NOT NULL,
    result_type public.citext NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    process_state public.citext,
    sort_key integer
);


ALTER TABLE public.t_mts_pt_db_jobs_cached OWNER TO d3l243;

--
-- Name: t_mts_pt_db_jobs_cached_cached_info_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_mts_pt_db_jobs_cached ALTER COLUMN cached_info_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_mts_pt_db_jobs_cached_cached_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_mts_pt_db_jobs_cached pk_t_mts_pt_db_jobs_cached; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mts_pt_db_jobs_cached
    ADD CONSTRAINT pk_t_mts_pt_db_jobs_cached PRIMARY KEY (cached_info_id);

--
-- Name: ix_t_mts_pt_db_jobs_cached_dbname_job; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_pt_db_jobs_cached_dbname_job ON public.t_mts_pt_db_jobs_cached USING btree (peptide_db_name, job);

--
-- Name: ix_t_mts_pt_db_jobs_cached_job; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_pt_db_jobs_cached_job ON public.t_mts_pt_db_jobs_cached USING btree (job);

--
-- Name: ix_t_mts_pt_db_jobs_cached_sort_key; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_pt_db_jobs_cached_sort_key ON public.t_mts_pt_db_jobs_cached USING btree (sort_key);

--
-- Name: t_mts_pt_db_jobs_cached trig_t_mts_pt_db_jobs_cached_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_mts_pt_db_jobs_cached_after_insert AFTER INSERT ON public.t_mts_pt_db_jobs_cached FOR EACH ROW EXECUTE FUNCTION public.trigfn_t_mts_pt_db_jobs_cached_after_insert_or_update();

--
-- Name: t_mts_pt_db_jobs_cached trig_t_mts_pt_db_jobs_cached_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_mts_pt_db_jobs_cached_after_update AFTER UPDATE ON public.t_mts_pt_db_jobs_cached FOR EACH ROW WHEN ((old.job <> new.job)) EXECUTE FUNCTION public.trigfn_t_mts_pt_db_jobs_cached_after_insert_or_update();

--
-- Name: TABLE t_mts_pt_db_jobs_cached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_pt_db_jobs_cached TO readaccess;
GRANT SELECT ON TABLE public.t_mts_pt_db_jobs_cached TO writeaccess;

