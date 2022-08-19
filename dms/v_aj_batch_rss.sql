--
-- Name: v_aj_batch_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aj_batch_rss AS
 SELECT ('Batch '::text || (statsq.batch_id)::text) AS post_title,
    ''::text AS url_title,
    statsq.jobs_finished AS post_date,
    (((((((((((statsq.batch_description)::text || ' ('::text) || 'Total:'::text) || (statsq.total_jobs)::text) || ', Complete:'::text) || (statsq.completed_jobs)::text) || ', Failed:'::text) || (statsq.failed_jobs)::text) || ', Busy:'::text) || (statsq.busy_jobs)::text) || ')'::text) AS post_body,
    statsq.batch_created
   FROM ( SELECT b.batch_id,
            b.batch_created,
            b.batch_description,
            count(j.job) AS total_jobs,
            sum(
                CASE
                    WHEN (j.job_state_id = ANY (ARRAY[4, 14])) THEN 1
                    ELSE 0
                END) AS completed_jobs,
            sum(
                CASE
                    WHEN (j.job_state_id = ANY (ARRAY[5, 6, 7, 12, 15, 18, 99])) THEN 1
                    ELSE 0
                END) AS failed_jobs,
            sum(
                CASE
                    WHEN (j.job_state_id = ANY (ARRAY[2, 3, 8, 9, 10, 11, 16, 17])) THEN 1
                    ELSE 0
                END) AS busy_jobs,
            max(j.finish) AS jobs_finished
           FROM (public.t_analysis_job_batches b
             JOIN public.t_analysis_job j ON ((b.batch_id = j.batch_id)))
          GROUP BY b.batch_description, b.batch_created, b.batch_id
         HAVING (max(j.finish) > (CURRENT_TIMESTAMP - '30 days'::interval))) statsq
  WHERE (statsq.total_jobs = (statsq.failed_jobs + statsq.completed_jobs));


ALTER TABLE public.v_aj_batch_rss OWNER TO d3l243;

--
-- Name: TABLE v_aj_batch_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aj_batch_rss TO readaccess;
GRANT SELECT ON TABLE public.v_aj_batch_rss TO writeaccess;

