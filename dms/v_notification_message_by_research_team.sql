--
-- Name: v_notification_message_by_research_team; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_message_by_research_team AS
 SELECT v_notification_requested_run_batches_by_research_team.seq,
    v_notification_requested_run_batches_by_research_team.event,
    v_notification_requested_run_batches_by_research_team.entity,
    v_notification_requested_run_batches_by_research_team.name,
    v_notification_requested_run_batches_by_research_team.campaign,
    v_notification_requested_run_batches_by_research_team.person,
    v_notification_requested_run_batches_by_research_team.person_role,
    v_notification_requested_run_batches_by_research_team.entered,
    v_notification_requested_run_batches_by_research_team.entity_type,
    v_notification_requested_run_batches_by_research_team.username,
    replace((v_notification_requested_run_batches_by_research_team.link_template)::text, '@ID@'::text, (v_notification_requested_run_batches_by_research_team.entity)::text) AS link,
    v_notification_requested_run_batches_by_research_team.event_type_id
   FROM public.v_notification_requested_run_batches_by_research_team
  WHERE (v_notification_requested_run_batches_by_research_team.entered > (CURRENT_TIMESTAMP - '24:00:00'::interval))
UNION
 SELECT v_notification_analysis_job_request_by_research_team.seq,
    v_notification_analysis_job_request_by_research_team.event,
    v_notification_analysis_job_request_by_research_team.entity,
    v_notification_analysis_job_request_by_research_team.name,
    v_notification_analysis_job_request_by_research_team.campaign,
    v_notification_analysis_job_request_by_research_team.person,
    v_notification_analysis_job_request_by_research_team.person_role,
    v_notification_analysis_job_request_by_research_team.entered,
    v_notification_analysis_job_request_by_research_team.entity_type,
    v_notification_analysis_job_request_by_research_team.username,
    replace((v_notification_analysis_job_request_by_research_team.link_template)::text, '@ID@'::text, (v_notification_analysis_job_request_by_research_team.entity)::text) AS link,
    v_notification_analysis_job_request_by_research_team.event_type_id
   FROM public.v_notification_analysis_job_request_by_research_team
  WHERE (v_notification_analysis_job_request_by_research_team.entered > (CURRENT_TIMESTAMP - '24:00:00'::interval))
UNION
 SELECT src.seq,
    src.event,
    src.entity,
    src.name,
    src.campaign,
    src.person,
    src.person_role,
    src.entered,
    src.entity_type,
    src.username,
    replace((src.link_template)::text, '@ID@'::text, (src.entity)::text) AS link,
    src.event_type_id
   FROM (public.v_notification_analysis_job_request_by_request_owner src
     LEFT JOIN ( SELECT v_notification_analysis_job_request_by_research_team.event,
            v_notification_analysis_job_request_by_research_team.entity,
            v_notification_analysis_job_request_by_research_team.username
           FROM public.v_notification_analysis_job_request_by_research_team
          WHERE (v_notification_analysis_job_request_by_research_team.entered > (CURRENT_TIMESTAMP - '24:00:00'::interval))) filterq ON (((src.event OPERATOR(public.=) filterq.event) AND (src.entity = filterq.entity) AND (src.username OPERATOR(public.=) filterq.username))))
  WHERE ((src.entered > (CURRENT_TIMESTAMP - '24:00:00'::interval)) AND (filterq.username IS NULL))
UNION
 SELECT v_notification_sample_prep_request_by_research_team.seq,
    v_notification_sample_prep_request_by_research_team.event,
    v_notification_sample_prep_request_by_research_team.entity,
    v_notification_sample_prep_request_by_research_team.name,
    v_notification_sample_prep_request_by_research_team.campaign,
    v_notification_sample_prep_request_by_research_team.person,
    v_notification_sample_prep_request_by_research_team.person_role,
    v_notification_sample_prep_request_by_research_team.entered,
    v_notification_sample_prep_request_by_research_team.entity_type,
    v_notification_sample_prep_request_by_research_team.username,
    replace((v_notification_sample_prep_request_by_research_team.link_template)::text, '@ID@'::text, (v_notification_sample_prep_request_by_research_team.entity)::text) AS link,
    v_notification_sample_prep_request_by_research_team.event_type_id
   FROM public.v_notification_sample_prep_request_by_research_team
  WHERE (v_notification_sample_prep_request_by_research_team.entered > (CURRENT_TIMESTAMP - '24:00:00'::interval))
UNION
 SELECT v_notification_datasets_by_research_team.seq,
    v_notification_datasets_by_research_team.event,
    v_notification_datasets_by_research_team.entity,
    v_notification_datasets_by_research_team.name,
    v_notification_datasets_by_research_team.campaign,
    v_notification_datasets_by_research_team.person,
    v_notification_datasets_by_research_team.person_role,
    v_notification_datasets_by_research_team.entered,
    v_notification_datasets_by_research_team.entity_type,
    v_notification_datasets_by_research_team.username,
    replace((v_notification_datasets_by_research_team.link_template)::text, '@ID@'::text, (v_notification_datasets_by_research_team.entity)::text) AS link,
    v_notification_datasets_by_research_team.event_type_id
   FROM public.v_notification_datasets_by_research_team
  WHERE (v_notification_datasets_by_research_team.entered > (CURRENT_TIMESTAMP - '24:00:00'::interval));


ALTER VIEW public.v_notification_message_by_research_team OWNER TO d3l243;

--
-- Name: TABLE v_notification_message_by_research_team; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_message_by_research_team TO readaccess;
GRANT SELECT ON TABLE public.v_notification_message_by_research_team TO writeaccess;

