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
-- Name: TABLE t_mts_peak_matching_tasks_cached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_peak_matching_tasks_cached TO readaccess;

