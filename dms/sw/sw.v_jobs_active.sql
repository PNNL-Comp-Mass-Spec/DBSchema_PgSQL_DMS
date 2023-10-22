--
-- Name: v_jobs_active; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_jobs_active AS
 SELECT j.job,
    j.priority,
    j.script,
    j.job_state_b AS job_state,
    j.dataset,
    j.imported,
    j.start,
    j.finish,
    COALESCE(ajpga.group_name, ''::public.citext) AS processor_group,
    d.param_file_name AS parameter_file_name,
    d.settings_file_name,
    j.results_folder_name,
    j.transfer_folder_path,
    row_number() OVER (ORDER BY
        CASE
            WHEN (j.job_state_b OPERATOR(public.=) 'Failed'::public.citext) THEN 'a'::public.citext
            ELSE j.job_state_b
        END DESC, j.job) AS sort_order
   FROM ((sw.v_pipeline_jobs_list_report j
     LEFT JOIN public.v_analysis_job_processor_group_association_recent ajpga ON ((j.job = ajpga.job)))
     LEFT JOIN public.t_analysis_job d ON ((j.job = d.job)))
  WHERE (((j.job_state_b OPERATOR(public.<>) ALL (ARRAY['complete'::public.citext, 'failed'::public.citext])) AND (j.imported >= (CURRENT_TIMESTAMP - '120 days'::interval))) OR ((j.job_state_b OPERATOR(public.<>) 'complete'::public.citext) AND (j.imported >= (CURRENT_TIMESTAMP - '31 days'::interval))) OR (j.imported >= (CURRENT_TIMESTAMP - '1 day'::interval)) OR (j.finish >= (CURRENT_TIMESTAMP - '1 day'::interval)))
UNION
 SELECT pj.job,
    pj.priority,
    pj.tool AS script,
    (((
        CASE
            WHEN (pj.state = 1) THEN 'New'::public.citext
            WHEN (pj.state = 8) THEN 'Holding'::public.citext
            ELSE '??'::public.citext
        END)::text || (' (not in Pipeline DB)'::public.citext)::text))::public.citext AS job_state,
    pj.dataset,
    NULL::timestamp without time zone AS imported,
    NULL::timestamp without time zone AS start,
    NULL::timestamp without time zone AS finish,
    ''::public.citext AS processor_group,
    pj.parameter_file_name,
    pj.settings_file_name,
    ''::public.citext AS results_folder_name,
    pj.transfer_folder_path,
    0 AS sort_order
   FROM (sw.v_dms_pipeline_jobs pj
     LEFT JOIN sw.t_jobs j ON ((pj.job = j.job)))
  WHERE ((pj.state = ANY (ARRAY[1, 8])) AND (j.job IS NULL));


ALTER TABLE sw.v_jobs_active OWNER TO d3l243;

--
-- Name: TABLE v_jobs_active; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_jobs_active TO readaccess;
GRANT SELECT ON TABLE sw.v_jobs_active TO writeaccess;

