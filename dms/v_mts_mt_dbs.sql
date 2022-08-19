--
-- Name: v_mts_mt_dbs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_mt_dbs AS
 SELECT mtdbs.mt_db_id,
    mtdbs.mt_db_name,
    mtdbs.state,
    mtdbs.description,
    mtdbs.organism,
    mtdbs.campaign,
    mtdbs.msms_jobs,
    mtdbs.ms_jobs,
    mtdbs.peptide_db,
    mtdbs.server_name,
    mtdbs.state_id
   FROM public.t_mts_mt_dbs_cached mtdbs;


ALTER TABLE public.v_mts_mt_dbs OWNER TO d3l243;

--
-- Name: TABLE v_mts_mt_dbs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_mt_dbs TO readaccess;
GRANT SELECT ON TABLE public.v_mts_mt_dbs TO writeaccess;

