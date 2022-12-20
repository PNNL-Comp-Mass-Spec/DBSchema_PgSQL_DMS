--
-- Name: v_peptide_atlas_job_parameters; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_peptide_atlas_job_parameters AS
 SELECT selectionq.job,
    selectionq.parameters,
    selectionq.output_folder_name
   FROM ( SELECT lookupq.job,
            lookupq.parameters,
            lookupq.output_folder_name,
            row_number() OVER (PARTITION BY lookupq.job ORDER BY lookupq.historyjob) AS rowrank
           FROM ( SELECT j.job,
                    p.parameters,
                    js.output_folder_name,
                    0 AS historyjob
                   FROM ((sw.t_jobs j
                     JOIN sw.t_job_parameters p ON ((j.job = p.job)))
                     JOIN sw.t_job_steps js ON ((j.job = js.job)))
                  WHERE ((j.script OPERATOR(public.=) 'PeptideAtlas'::public.citext) AND (js.step = 1))
                UNION ALL
                 SELECT j.job,
                    p.parameters,
                    js.output_folder_name,
                    1 AS historyjob
                   FROM ((sw.t_jobs_history j
                     JOIN sw.t_job_parameters_history p ON (((j.job = p.job) AND (j.saved = p.saved))))
                     JOIN sw.t_job_steps_history js ON (((j.job = js.job) AND (j.saved = js.saved))))
                  WHERE ((j.script OPERATOR(public.=) 'PeptideAtlas'::public.citext) AND (js.step = 1) AND (j.most_recent_entry = 1))) lookupq) selectionq
  WHERE (selectionq.rowrank = 1);


ALTER TABLE sw.v_peptide_atlas_job_parameters OWNER TO d3l243;

--
-- Name: TABLE v_peptide_atlas_job_parameters; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_peptide_atlas_job_parameters TO readaccess;
GRANT SELECT ON TABLE sw.v_peptide_atlas_job_parameters TO writeaccess;

