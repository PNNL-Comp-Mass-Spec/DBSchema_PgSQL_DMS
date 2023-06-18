--
-- Name: v_event_log; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_event_log AS
 SELECT el.event_id,
    el.target_type,
        CASE el.target_type
            WHEN 1 THEN 'Campaign'::text
            WHEN 2 THEN 'Biomaterial'::text
            WHEN 3 THEN 'Experiment'::text
            WHEN 4 THEN 'Dataset'::text
            WHEN 5 THEN 'Job'::text
            WHEN 6 THEN 'DS Archive'::text
            WHEN 7 THEN 'DS ArchUpdate'::text
            WHEN 8 THEN 'DS Rating'::text
            WHEN 9 THEN 'Campaign Percent EMSL Funded'::text
            WHEN 10 THEN 'Campaign Data Release State'::text
            WHEN 11 THEN 'Requested Run'::text
            WHEN 12 THEN 'Analysis Job Request'::text
            WHEN 13 THEN 'Reference Compound'::text
            ELSE NULL::text
        END AS target,
    el.target_id,
    el.target_state,
        CASE
            WHEN (el.target_type = ANY (ARRAY[1, 2, 3, 13])) THEN
            CASE el.target_state
                WHEN 1 THEN 'Created'::text
                WHEN 0 THEN 'Deleted'::text
                ELSE NULL::text
            END
            WHEN (el.target_type = 4) THEN
            CASE
                WHEN ((el.target_state = 0) AND (el.prev_target_state > 0)) THEN 'Deleted'::text
                ELSE (dssn.dataset_state)::text
            END
            WHEN (el.target_type = 5) THEN
            CASE
                WHEN ((el.target_state = 0) AND (el.prev_target_state > 0)) THEN 'Deleted'::text
                ELSE (ajsn.job_state)::text
            END
            WHEN (el.target_type = 6) THEN
            CASE
                WHEN ((el.target_state = 0) AND (el.prev_target_state > 0)) THEN 'Deleted'::text
                ELSE (dasn.archive_state)::text
            END
            WHEN (el.target_type = 7) THEN (ausn.archive_update_state)::text
            WHEN (el.target_type = 8) THEN (dsrn.dataset_rating)::text
            WHEN (el.target_type = 9) THEN '% EMSL Funded'::text
            WHEN (el.target_type = 10) THEN (drr.release_restriction)::text
            WHEN (el.target_type = 11) THEN
            CASE
                WHEN ((el.target_state = 0) AND (el.prev_target_state > 0)) THEN 'Deleted'::text
                ELSE (rrsn.state_name)::text
            END
            WHEN (el.target_type = 12) THEN
            CASE
                WHEN ((el.target_state = 0) AND (el.prev_target_state > 0)) THEN 'Deleted'::text
                ELSE (ajrs.request_state)::text
            END
            ELSE NULL::text
        END AS state_name,
    el.prev_target_state,
    el.entered,
    el.entered_by
   FROM ((((((((public.t_event_log el
     LEFT JOIN public.t_dataset_rating_name dsrn ON (((el.target_state = dsrn.dataset_rating_id) AND (el.target_type = 8))))
     LEFT JOIN public.t_dataset_state_name dssn ON (((el.target_state = dssn.dataset_state_id) AND (el.target_type = 4))))
     LEFT JOIN public.t_dataset_archive_update_state_name ausn ON (((el.target_state = ausn.archive_update_state_id) AND (el.target_type = 7))))
     LEFT JOIN public.t_dataset_archive_state_name dasn ON (((el.target_state = dasn.archive_state_id) AND (el.target_type = 6))))
     LEFT JOIN public.t_analysis_job_state ajsn ON (((el.target_state = ajsn.job_state_id) AND (el.target_type = 5))))
     LEFT JOIN public.t_data_release_restrictions drr ON (((el.target_state = drr.release_restriction_id) AND (el.target_type = 10))))
     LEFT JOIN public.t_requested_run_state_name rrsn ON (((el.target_state = rrsn.state_id) AND (el.target_type = 11))))
     LEFT JOIN public.t_analysis_job_request_state ajrs ON (((el.target_state = ajrs.request_state_id) AND (el.target_type = 12))));


ALTER TABLE public.v_event_log OWNER TO d3l243;

--
-- Name: TABLE v_event_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_event_log TO readaccess;
GRANT SELECT ON TABLE public.v_event_log TO writeaccess;

