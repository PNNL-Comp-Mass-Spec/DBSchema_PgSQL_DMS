--
-- Name: v_mts_mt_dbs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_mt_dbs AS
 SELECT mt_db_id,
    mt_db_name,
    state,
    description,
    organism,
    campaign,
    msms_jobs,
    ms_jobs,
    peptide_db,
    server_name,
    state_id
   FROM public.t_mts_mt_dbs_cached mtdbs;


ALTER VIEW public.v_mts_mt_dbs OWNER TO d3l243;

--
-- Name: TABLE v_mts_mt_dbs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_mt_dbs TO readaccess;
GRANT SELECT ON TABLE public.v_mts_mt_dbs TO writeaccess;

