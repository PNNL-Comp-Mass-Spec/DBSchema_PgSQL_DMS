--
-- Name: v_entity_users_one_year; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_entity_users_one_year AS
 SELECT 'Analysis job owner'::text AS entity,
    t_analysis_job.owner_username AS username,
    count(*) AS items
   FROM public.t_analysis_job
  WHERE ((t_analysis_job.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_analysis_job.created <= CURRENT_TIMESTAMP))
  GROUP BY t_analysis_job.owner_username
UNION
 SELECT 'Analysis job request user'::text AS entity,
    u.username,
    count(*) AS items
   FROM (public.t_analysis_job_request ajr
     JOIN public.t_users u ON ((ajr.user_id = u.user_id)))
  WHERE ((ajr.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (ajr.created <= CURRENT_TIMESTAMP))
  GROUP BY u.username
UNION
 SELECT 'Biomaterial contact'::text AS entity,
    t_biomaterial.contact_username AS username,
    count(*) AS items
   FROM public.t_biomaterial
  WHERE ((t_biomaterial.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_biomaterial.created <= CURRENT_TIMESTAMP))
  GROUP BY t_biomaterial.contact_username
UNION
 SELECT 'Dataset operator'::text AS entity,
    t_dataset.operator_username AS username,
    count(*) AS items
   FROM public.t_dataset
  WHERE ((t_dataset.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_dataset.created <= CURRENT_TIMESTAMP))
  GROUP BY t_dataset.operator_username
UNION
 SELECT 'Experiment group researcher'::text AS entity,
    t_experiment_groups.researcher_username AS username,
    count(*) AS items
   FROM public.t_experiment_groups
  WHERE ((t_experiment_groups.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_experiment_groups.created <= CURRENT_TIMESTAMP))
  GROUP BY t_experiment_groups.researcher_username
UNION
 SELECT 'Experiment researcher'::text AS entity,
    t_experiments.researcher_username AS username,
    count(*) AS items
   FROM public.t_experiments
  WHERE ((t_experiments.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_experiments.created <= CURRENT_TIMESTAMP))
  GROUP BY t_experiments.researcher_username
UNION
 SELECT 'Cart config entered'::text AS entity,
    t_lc_cart_configuration.entered_by AS username,
    count(*) AS items
   FROM public.t_lc_cart_configuration
  WHERE ((t_lc_cart_configuration.entered >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_lc_cart_configuration.entered <= CURRENT_TIMESTAMP))
  GROUP BY t_lc_cart_configuration.entered_by
UNION
 SELECT 'Cart config updated'::text AS entity,
    t_lc_cart_configuration.updated_by AS username,
    count(*) AS items
   FROM public.t_lc_cart_configuration
  WHERE ((t_lc_cart_configuration.entered >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_lc_cart_configuration.entered <= CURRENT_TIMESTAMP))
  GROUP BY t_lc_cart_configuration.updated_by
UNION
 SELECT 'LC column operator'::text AS entity,
    t_lc_column.operator_username AS username,
    count(*) AS items
   FROM public.t_lc_column
  WHERE ((t_lc_column.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_lc_column.created <= CURRENT_TIMESTAMP))
  GROUP BY t_lc_column.operator_username
UNION
 SELECT 'Reference compount contact'::text AS entity,
    t_reference_compound.contact_username AS username,
    count(*) AS items
   FROM public.t_reference_compound
  WHERE ((t_reference_compound.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_reference_compound.created <= CURRENT_TIMESTAMP))
  GROUP BY t_reference_compound.contact_username
UNION
 SELECT 'Requested run requester'::text AS entity,
    t_requested_run.requester_username AS username,
    count(*) AS items
   FROM public.t_requested_run
  WHERE ((t_requested_run.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_requested_run.created <= CURRENT_TIMESTAMP))
  GROUP BY t_requested_run.requester_username
UNION
 SELECT 'Requested run updater'::text AS entity,
    (public.replace(t_requested_run.updated_by, 'PNL\'::public.citext, ''::public.citext))::public.citext AS username,
    count(*) AS items
   FROM public.t_requested_run
  WHERE ((t_requested_run.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_requested_run.created <= CURRENT_TIMESTAMP))
  GROUP BY (public.replace(t_requested_run.updated_by, 'PNL\'::public.citext, ''::public.citext))::public.citext
UNION
 SELECT countq.entity,
    (replace(public.replace(countq.entered_by, ' (via dmswebuser)'::public.citext, ''::public.citext), 'PNL\'::text, ''::text))::public.citext AS username,
    sum(countq.items) AS items
   FROM ( SELECT 'Analysis job state change in sw.t_jobs'::text AS entity,
            t_job_events.entered_by,
            count(*) AS items
           FROM sw.t_job_events
          WHERE ((t_job_events.entered >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_job_events.entered <= CURRENT_TIMESTAMP))
          GROUP BY t_job_events.entered_by) countq
  GROUP BY countq.entity, (replace(public.replace(countq.entered_by, ' (via dmswebuser)'::public.citext, ''::public.citext), 'PNL\'::text, ''::text))::public.citext
UNION
 SELECT 'Analysis job owner in sw.t_jobs'::text AS entity,
    t_jobs.owner_username AS username,
    count(*) AS items
   FROM sw.t_jobs
  WHERE ((t_jobs.imported >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_jobs.imported <= CURRENT_TIMESTAMP))
  GROUP BY t_jobs.owner_username
UNION
 SELECT 'Procedure usage in sw schema'::text AS entity,
    t_sp_usage.calling_user AS username,
    count(*) AS items
   FROM sw.t_sp_usage
  WHERE ((t_sp_usage.entered >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_sp_usage.entered <= CURRENT_TIMESTAMP))
  GROUP BY t_sp_usage.calling_user
UNION
 SELECT 'Capture task state change in cap.t_tasks'::text AS entity,
    (public.replace(t_task_events.entered_by, 'PNL\'::public.citext, ''::public.citext))::public.citext AS username,
    count(*) AS items
   FROM cap.t_task_events
  WHERE ((t_task_events.entered >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_task_events.entered <= CURRENT_TIMESTAMP))
  GROUP BY (public.replace(t_task_events.entered_by, 'PNL\'::public.citext, ''::public.citext))::public.citext
UNION
 SELECT 'Data package owner'::text AS entity,
    t_data_package.owner_username AS username,
    count(*) AS items
   FROM dpkg.t_data_package
  WHERE ((t_data_package.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_data_package.created <= CURRENT_TIMESTAMP))
  GROUP BY t_data_package.owner_username
UNION
 SELECT 'Data package requester'::text AS entity,
    t_data_package.requester AS username,
    count(*) AS items
   FROM dpkg.t_data_package
  WHERE ((t_data_package.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_data_package.created <= CURRENT_TIMESTAMP))
  GROUP BY t_data_package.requester
UNION
 SELECT replaceq.entity,
        CASE
            WHEN (replaceq.semicolon_position > 1) THEN ("left"((replaceq.entered_by)::text, (replaceq.semicolon_position - 1)))::public.citext
            ELSE replaceq.entered_by
        END AS username,
    sum(replaceq.items) AS items
   FROM ( SELECT positionq.entity,
                CASE
                    WHEN ((positionq.via_position > 1) AND ((positionq.semicolon_position = 0) OR (positionq.via_position < positionq.semicolon_position))) THEN ("left"((positionq.entered_by)::text, (positionq.via_position - 1)))::public.citext
                    ELSE positionq.entered_by
                END AS entered_by,
            positionq.semicolon_position,
            sum(positionq.items) AS items
           FROM ( SELECT countq.entity,
                    countq.entered_by,
                    POSITION((' (via'::text) IN (countq.entered_by)) AS via_position,
                    POSITION((';'::text) IN (countq.entered_by)) AS semicolon_position,
                    countq.items
                   FROM ( SELECT ('Entity state change: '::text || (v_event_log.target)::text) AS entity,
                            (public.replace(v_event_log.entered_by, 'PNL\'::public.citext, ''::public.citext))::public.citext AS entered_by,
                            count(*) AS items
                           FROM public.v_event_log
                          WHERE ((v_event_log.entered >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (v_event_log.entered <= CURRENT_TIMESTAMP))
                          GROUP BY ('Entity state change: '::text || (v_event_log.target)::text), (public.replace(v_event_log.entered_by, 'PNL\'::public.citext, ''::public.citext))::public.citext) countq) positionq
          GROUP BY positionq.entity,
                CASE
                    WHEN ((positionq.via_position > 1) AND ((positionq.semicolon_position = 0) OR (positionq.via_position < positionq.semicolon_position))) THEN ("left"((positionq.entered_by)::text, (positionq.via_position - 1)))::public.citext
                    ELSE positionq.entered_by
                END, positionq.semicolon_position) replaceq
  GROUP BY replaceq.entity,
        CASE
            WHEN (replaceq.semicolon_position > 1) THEN ("left"((replaceq.entered_by)::text, (replaceq.semicolon_position - 1)))::public.citext
            ELSE replaceq.entered_by
        END
UNION
 SELECT 'Requested run batch user'::text AS entity,
    u.username,
    count(*) AS items
   FROM (public.t_requested_run_batches rrb
     JOIN public.t_users u ON ((rrb.owner_user_id = u.user_id)))
  WHERE ((rrb.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (rrb.created <= CURRENT_TIMESTAMP))
  GROUP BY u.username
UNION
 SELECT 'Requested run batch group user'::text AS entity,
    u.username,
    count(*) AS items
   FROM (public.t_requested_run_batch_group rrbg
     JOIN public.t_users u ON ((rrbg.owner_user_id = u.user_id)))
  WHERE ((rrbg.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (rrbg.created <= CURRENT_TIMESTAMP))
  GROUP BY u.username
UNION
 SELECT 'Sample prep request requester'::text AS entity,
    t_sample_prep_request.requester_username AS username,
    count(*) AS items
   FROM public.t_sample_prep_request
  WHERE ((t_sample_prep_request.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_sample_prep_request.created <= CURRENT_TIMESTAMP))
  GROUP BY t_sample_prep_request.requester_username
UNION
 SELECT matchq.entity,
    (matchq.assigned_personnel)::public.citext AS username,
    matchq.items
   FROM ( SELECT splitq.entity,
                CASE
                    WHEN (POSITION(('('::text) IN (splitq.assigned_personnel)) > 0) THEN (regexp_match(splitq.assigned_personnel, '\((.+)\)'::text))[1]
                    ELSE splitq.assigned_personnel
                END AS assigned_personnel,
            splitq.items
           FROM ( SELECT countq.entity,
                    TRIM(BOTH FROM public.regexp_split_to_table(countq.assigned_personnel, ';'::public.citext)) AS assigned_personnel,
                    countq.items
                   FROM ( SELECT 'Sample prep request personnel'::text AS entity,
                            t_sample_prep_request.assigned_personnel,
                            count(*) AS items
                           FROM public.t_sample_prep_request
                          WHERE ((t_sample_prep_request.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_sample_prep_request.created <= CURRENT_TIMESTAMP))
                          GROUP BY t_sample_prep_request.assigned_personnel) countq) splitq) matchq
  WHERE (NOT (matchq.assigned_personnel IS NULL))
UNION
 SELECT 'Sample submission receiver'::text AS entity,
    u.username,
    count(*) AS items
   FROM (public.t_sample_submission ss
     JOIN public.t_users u ON ((ss.received_by_user_id = u.user_id)))
  WHERE ((ss.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (ss.created <= CURRENT_TIMESTAMP))
  GROUP BY u.username
UNION
 SELECT 'New user'::text AS entity,
    t_users.username,
    count(*) AS items
   FROM public.t_users
  WHERE ((t_users.created >= (CURRENT_TIMESTAMP - '1 year'::interval)) AND (t_users.created <= CURRENT_TIMESTAMP))
  GROUP BY t_users.username;


ALTER VIEW public.v_entity_users_one_year OWNER TO d3l243;

--
-- Name: TABLE v_entity_users_one_year; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_entity_users_one_year TO readaccess;
GRANT SELECT ON TABLE public.v_entity_users_one_year TO writeaccess;

