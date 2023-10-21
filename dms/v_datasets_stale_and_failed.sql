--
-- Name: v_datasets_stale_and_failed; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_datasets_stale_and_failed AS
 WITH jobstepstatus(dataset_id, activesteps, activearchivestatussteps) AS (
         SELECT j.dataset_id,
            count(js.step) AS active_steps,
            sum(
                CASE
                    WHEN (js.tool OPERATOR(public.=) ANY (ARRAY['ArchiveStatusCheck'::public.citext, 'ArchiveVerify'::public.citext])) THEN 1
                    ELSE 0
                END) AS active_archive_status_steps
           FROM ((cap.t_task_steps js
             JOIN cap.t_tasks j ON ((js.job = j.job)))
             JOIN public.t_dataset_archive da ON ((j.dataset_id = da.dataset_id)))
          WHERE ((da.archive_state_id = ANY (ARRAY[2, 7, 12])) AND (js.state <> ALL (ARRAY[3, 5])))
          GROUP BY j.dataset_id
        )
 SELECT unionq.warning_message,
    unionq.dataset,
    unionq.dataset_id,
    unionq.dataset_created,
    unionq.instrument,
    (unionq.state)::public.citext AS state,
    unionq.state_date,
    unionq.script,
    unionq.tool,
    unionq.runtime_minutes,
    unionq.step_state,
    unionq.processor,
    unionq.start,
    unionq.step,
    unionq.storage_path
   FROM ( SELECT tasksteps.warning_message,
            ds.dataset,
            ds.dataset_id,
            ds.created AS dataset_created,
            instname.instrument,
            ((dsn.dataset_state)::text || ' (dataset)'::text) AS state,
            ds.last_affected AS state_date,
            tasksteps.script,
            tasksteps.tool,
            tasksteps.runtime_minutes,
            tasksteps.state_name AS step_state,
            tasksteps.processor,
            tasksteps.start,
            tasksteps.step,
            ((spath.vol_name_client)::text || (spath.storage_path)::text) AS storage_path
           FROM ((((cap.v_task_steps_stale_and_failed tasksteps
             JOIN public.t_dataset ds ON ((tasksteps.dataset_id = ds.dataset_id)))
             JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
             JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
             JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
        UNION
         SELECT
                CASE
                    WHEN ((ds.dataset_state_id = ANY (ARRAY[5, 8, 12])) AND (ds.last_affected >= (CURRENT_TIMESTAMP - '14 days'::interval))) THEN 'Capture failed within the last 14 days'::text
                    WHEN ((ds.dataset_state_id = ANY (ARRAY[2, 7, 11])) AND ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ds.last_affected)::timestamp with time zone)) / 3600.0) >= (12)::numeric)) THEN 'Capture in progress over 12 hours'::text
                    WHEN ((ds.dataset_state_id = 1) AND (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ds.last_affected)::timestamp with time zone)) / (86400)::numeric)) >= (14)::numeric)) THEN 'Uncaptured (new) over 14 days'::text
                    ELSE ''::text
                END AS warning_message,
            ds.dataset,
            ds.dataset_id,
            ds.created AS dataset_created,
            instname.instrument,
            ((dsn.dataset_state)::text || (' (dataset)'::public.citext)::text) AS state,
            ds.last_affected AS state_date,
            ''::public.citext AS script,
            ''::public.citext AS tool,
            0 AS runtime_minutes,
            ''::public.citext AS step_state,
            ''::public.citext AS processor,
            NULL::timestamp without time zone AS start,
            0 AS step,
            ((spath.vol_name_client)::text || (spath.storage_path)::text) AS storage_path
           FROM (((public.t_dataset ds
             JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
             JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
             JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
          WHERE (ds.dataset_state_id = ANY (ARRAY[1, 2, 5, 7, 8, 11, 12]))
        UNION
         SELECT
                CASE
                    WHEN ((da.archive_state_id = ANY (ARRAY[6, 8, 13])) AND (da.archive_state_last_affected >= (CURRENT_TIMESTAMP - '14 days'::interval))) THEN 'Archive failed within the last 14 days'::text
                    WHEN ((da.archive_state_id = ANY (ARRAY[2, 7, 12])) AND ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (da.archive_state_last_affected)::timestamp with time zone)) / 3600.0) >= (12)::numeric) AND (jobstepstatus.activesteps > jobstepstatus.activearchivestatussteps)) THEN 'Archive in progress over 12 hours'::text
                    WHEN ((da.archive_state_id = ANY (ARRAY[2, 7, 12])) AND (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (da.archive_state_last_affected)::timestamp with time zone)) / (86400)::numeric)) >= (5)::numeric)) THEN 'Archive verification in progress over 5 days'::text
                    WHEN ((da.archive_state_id = ANY (ARRAY[1, 11])) AND (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (da.archive_state_last_affected)::timestamp with time zone)) / (86400)::numeric)) >= (14)::numeric)) THEN 'Archive State New or Verification Required over 14 days'::text
                    ELSE ''::text
                END AS warning_message,
            ds.dataset,
            ds.dataset_id,
            ds.created AS dataset_created,
            instname.instrument,
            ((dasn.archive_state)::text || (' (archive)'::public.citext)::text) AS state,
            da.archive_state_last_affected AS state_date,
            ''::public.citext AS script,
            ''::public.citext AS tool,
            0 AS runtime_minutes,
            ''::public.citext AS step_state,
            ''::public.citext AS processor,
            NULL::timestamp without time zone AS start,
            0 AS step,
            ((spath.vol_name_client)::text || (spath.storage_path)::text) AS storage_path
           FROM ((((((public.t_dataset_archive da
             JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
             JOIN public.t_dataset_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)))
             JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
             JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
             JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
             LEFT JOIN jobstepstatus ON ((da.dataset_id = jobstepstatus.dataset_id)))
          WHERE ((da.archive_state_id = ANY (ARRAY[1, 2, 6, 7, 8, 11, 12, 13])) AND (NOT (EXISTS ( SELECT t_misc_options.name,
                    t_misc_options.id,
                    t_misc_options.value,
                    t_misc_options.comment
                   FROM public.t_misc_options
                  WHERE ((t_misc_options.name OPERATOR(public.=) 'ArchiveDisabled'::public.citext) AND (t_misc_options.value = 1))))))) unionq
  WHERE (unionq.warning_message <> ''::text);


ALTER TABLE public.v_datasets_stale_and_failed OWNER TO d3l243;

--
-- Name: TABLE v_datasets_stale_and_failed; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_datasets_stale_and_failed TO readaccess;
GRANT SELECT ON TABLE public.v_datasets_stale_and_failed TO writeaccess;

