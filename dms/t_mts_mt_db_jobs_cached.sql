--
-- Name: t_mts_mt_db_jobs_cached; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mts_mt_db_jobs_cached (
    cached_info_id integer NOT NULL,
    server_name public.citext NOT NULL,
    mt_db_name public.citext NOT NULL,
    job integer NOT NULL,
    result_type public.citext NOT NULL,
    last_affected timestamp without time zone NOT NULL,
    process_state public.citext,
    sort_key integer
);


ALTER TABLE public.t_mts_mt_db_jobs_cached OWNER TO d3l243;

--
-- Name: TABLE t_mts_mt_db_jobs_cached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_mt_db_jobs_cached TO readaccess;

