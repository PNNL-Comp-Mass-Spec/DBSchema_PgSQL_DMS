--
-- Name: v_analysis_job_request_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_request_rss AS
 SELECT ((('Request '::text || (request_id)::text) || ' - '::text) || (request_name)::text) AS post_title,
    request_id AS url_title,
    jobs_finished AS post_date,
    (((((((((((((((((request_name)::text || '|'::text) || (requester)::text) || '|'::text) || ' ('::text) || 'Total:'::text) || (total_jobs)::text) || ', '::text) || 'Complete:'::text) || (completed_jobs)::text) || ', '::text) || 'Failed:'::text) || (failed_jobs)::text) || ', '::text) || 'Busy:'::text) || (busy_jobs)::text) || ')'::text) AS post_body,
    (((((request_id)::text || '-'::text) || (total_jobs)::text) || '-'::text) || (completed_jobs)::text) AS guid
   FROM ( SELECT ajr.request_id,
            ajr.request_name,
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
            max(j.finish) AS jobs_finished,
            u.name AS requester,
            u.username
           FROM ((public.t_analysis_job j
             JOIN public.t_analysis_job_request ajr ON ((j.request_id = ajr.request_id)))
             JOIN public.t_users u ON ((ajr.user_id = u.user_id)))
          GROUP BY ajr.request_name, ajr.request_id, u.name, ajr.request_state_id, u.username
         HAVING ((max(j.finish) > (CURRENT_TIMESTAMP - '30 days'::interval)) AND (ajr.request_id > 1))) lookupq
  WHERE (total_jobs = (failed_jobs + completed_jobs));


ALTER VIEW public.v_analysis_job_request_rss OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_request_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_request_rss TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_request_rss TO writeaccess;

