--
-- Name: v_analysis_job_processor_group_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_group_detail_report AS
 SELECT ajpg.group_id AS id,
    ajpg.group_name,
    ajpg.group_enabled,
    'Y'::text AS general_processing,
    ajpg.group_description,
    ajpg.group_created,
    COALESCE(countq.processor_count, (0)::bigint) AS members,
    public.get_aj_processor_group_membership_list(ajpg.group_id, 1) AS enabled_processors,
    public.get_aj_processor_group_membership_list(ajpg.group_id, 0) AS disabled_processors,
    public.get_aj_processor_group_associated_jobs(ajpg.group_id, 2) AS associated_jobs
   FROM (public.t_analysis_job_processor_group ajpg
     LEFT JOIN ( SELECT ajpgm.group_id,
            count(*) AS processor_count
           FROM public.t_analysis_job_processor_group_membership ajpgm
          GROUP BY ajpgm.group_id) countq ON ((ajpg.group_id = countq.group_id)));


ALTER TABLE public.v_analysis_job_processor_group_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_group_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_group_detail_report TO readaccess;

