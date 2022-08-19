--
-- Name: t_mts_peak_matching_tasks_cached; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mts_peak_matching_tasks_cached (
    cached_info_id integer NOT NULL,
    tool_name public.citext NOT NULL,
    mts_job_id integer NOT NULL,
    job_start timestamp without time zone,
    job_finish timestamp without time zone,
    comment public.citext,
    state_id integer NOT NULL,
    task_server public.citext NOT NULL,
    task_database public.citext NOT NULL,
    task_id integer NOT NULL,
    assigned_processor_name public.citext,
    tool_version public.citext,
    dms_job_count integer,
    dms_job integer NOT NULL,
    output_folder_path public.citext,
    results_url public.citext,
    amt_count_1pct_fdr integer,
    amt_count_5pct_fdr integer,
    amt_count_10pct_fdr integer,
    amt_count_25pct_fdr integer,
    amt_count_50pct_fdr integer,
    refine_mass_cal_ppm_shift numeric(9,4),
    md_id integer,
    qid integer,
    ini_file_name public.citext,
    comparison_mass_tag_count integer,
    md_state smallint
);


ALTER TABLE public.t_mts_peak_matching_tasks_cached OWNER TO d3l243;

--
-- Name: t_mts_peak_matching_tasks_cached_cached_info_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_mts_peak_matching_tasks_cached ALTER COLUMN cached_info_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_mts_peak_matching_tasks_cached_cached_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_mts_peak_matching_tasks_cached pk_t_mts_peak_matching_tasks_cached; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mts_peak_matching_tasks_cached
    ADD CONSTRAINT pk_t_mts_peak_matching_tasks_cached PRIMARY KEY (cached_info_id);

--
-- Name: ix_t_mts_peak_matching_tasks_cached_dmsjob; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_peak_matching_tasks_cached_dmsjob ON public.t_mts_peak_matching_tasks_cached USING btree (dms_job);

--
-- Name: ix_t_mts_peak_matching_tasks_cached_job_start; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_peak_matching_tasks_cached_job_start ON public.t_mts_peak_matching_tasks_cached USING btree (job_start);

--
-- Name: ix_t_mts_peak_matching_tasks_cached_mtsjob_dmsjob; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_peak_matching_tasks_cached_mtsjob_dmsjob ON public.t_mts_peak_matching_tasks_cached USING btree (mts_job_id, dms_job);

--
-- Name: ix_t_mts_peak_matching_tasks_cached_task_db; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_peak_matching_tasks_cached_task_db ON public.t_mts_peak_matching_tasks_cached USING btree (task_database) INCLUDE (dms_job);

--
-- Name: ix_t_mts_peak_matching_tasks_cached_tool_dmsjob; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_mts_peak_matching_tasks_cached_tool_dmsjob ON public.t_mts_peak_matching_tasks_cached USING btree (tool_name, dms_job);

--
-- Name: TABLE t_mts_peak_matching_tasks_cached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_peak_matching_tasks_cached TO readaccess;
GRANT SELECT ON TABLE public.t_mts_peak_matching_tasks_cached TO writeaccess;

