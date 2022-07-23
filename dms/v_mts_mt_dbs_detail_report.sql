--
-- Name: v_mts_mt_dbs_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_mt_dbs_detail_report AS
 SELECT mtdbs.mt_db_name,
    mtdbs.mt_db_id,
    mtdbs.description,
    mtdbs.organism,
    mtdbs.campaign,
    mtdbs.msms_jobs,
    mtdbs.ms_jobs,
    sum(
        CASE
            WHEN (pmtasks.task_id IS NULL) THEN 0
            ELSE 1
        END) AS pm_task_count,
    mtdbs.peptide_db,
    mtdbs.peptide_db_count,
    mtdbs.server_name,
    mtdbs.state,
    mtdbs.state_id,
    mtdbs.last_affected
   FROM (public.t_mts_mt_dbs_cached mtdbs
     LEFT JOIN public.t_mts_peak_matching_tasks_cached pmtasks ON ((mtdbs.mt_db_name OPERATOR(public.=) pmtasks.task_database)))
  GROUP BY mtdbs.mt_db_name, mtdbs.mt_db_id, mtdbs.description, mtdbs.organism, mtdbs.campaign, mtdbs.msms_jobs, mtdbs.ms_jobs, mtdbs.peptide_db, mtdbs.peptide_db_count, mtdbs.server_name, mtdbs.state, mtdbs.state_id, mtdbs.last_affected;


ALTER TABLE public.v_mts_mt_dbs_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_mts_mt_dbs_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_mt_dbs_detail_report TO readaccess;

