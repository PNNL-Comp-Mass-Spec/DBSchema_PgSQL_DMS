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
-- Name: TABLE t_mts_mt_dbs_cached; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_mt_dbs_cached TO readaccess;

