--
-- Name: v_analysis_job_processor_group_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_group_list_report AS
 SELECT ajpg.group_id AS id,
    ajpg.group_name,
    ajpg.group_description,
    ajpg.group_enabled,
    'Y'::text AS general_processing,
    countq.enabled_procs_count AS enabled_procs,
    countq.disabled_procs_count AS disabled_procs,
    public.get_aj_processor_group_associated_jobs(ajpg.group_id, 1) AS associated_jobs,
    ajpg.group_created
   FROM (public.t_analysis_job_processor_group ajpg
     JOIN ( SELECT ajpg_1.group_id,
            sum(
                CASE
                    WHEN (ajpgm.membership_enabled = 'Y'::bpchar) THEN 1
                    ELSE 0
                END) AS enabled_procs_count,
            sum(
                CASE
                    WHEN (ajpgm.membership_enabled <> 'Y'::bpchar) THEN 1
                    ELSE 0
                END) AS disabled_procs_count
           FROM (public.t_analysis_job_processor_group ajpg_1
             LEFT JOIN public.t_analysis_job_processor_group_membership ajpgm ON ((ajpg_1.group_id = ajpgm.group_id)))
          GROUP BY ajpg_1.group_id) countq ON ((ajpg.group_id = countq.group_id)));


ALTER TABLE public.v_analysis_job_processor_group_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_group_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_group_list_report TO readaccess;

