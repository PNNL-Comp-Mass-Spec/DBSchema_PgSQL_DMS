--
-- Name: v_mts_pt_dbs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_pt_dbs AS
 SELECT peptide_db_id,
    peptide_db_name,
    state,
    description,
    organism,
    msms_jobs,
    sic_jobs,
    server_name,
    state_id
   FROM public.t_mts_pt_dbs_cached ptdbs;


ALTER VIEW public.v_mts_pt_dbs OWNER TO d3l243;

--
-- Name: TABLE v_mts_pt_dbs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_pt_dbs TO readaccess;
GRANT SELECT ON TABLE public.v_mts_pt_dbs TO writeaccess;

