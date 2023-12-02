--
-- Name: v_analysis_job_request_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_request_rss AS
 SELECT ((('Request '::text || (lookupq.request_id)::text) || ' - '::text) || (lookupq.request_name)::text) AS post_title,
    lookupq.request_id AS url_title,
    lookupq.jobs_finished AS post_date,
    (((((((((((((((((lookupq.request_name)::text || '|'::text) || (lookupq.requester)::text) || '|'::text) || ' ('::text) || 'Total:'::text) || (lookupq.total_jobs)::text) || ', '::text) || 'Complete:'::text) || (lookupq.completed_jobs)::text) || ', '::text) || 'Failed:'::text) || (lookupq.failed_jobs)::text) || ', '::text) || 'Busy:'::text) || (lookupq.busy_jobs)::text) || ')'::text) AS post_body,
    (((((lookupq.request_id)::text || '-'::text) || (lookupq.total_jobs)::text) || '-'::text) || (lookupq.completed_jobs)::text) AS guid
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
  WHERE (lookupq.total_jobs = (lookupq.failed_jobs + lookupq.completed_jobs));


ALTER VIEW public.v_analysis_job_request_rss OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_request_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_request_rss TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_request_rss TO writeaccess;

