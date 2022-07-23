--
-- Name: v_notification_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_notification_entry AS
 SELECT t.prn,
    t.name,
        CASE
            WHEN (t.r1 > 0) THEN 'Yes'::text
            ELSE 'No'::text
        END AS requested_run_batch,
        CASE
            WHEN (t.r2 > 0) THEN 'Yes'::text
            ELSE 'No'::text
        END AS analysis_job_request,
        CASE
            WHEN (t.r3 > 0) THEN 'Yes'::text
            ELSE 'No'::text
        END AS sample_prep_request,
        CASE
            WHEN (t.r4 > 0) THEN 'Yes'::text
            ELSE 'No'::text
        END AS dataset_not_released,
        CASE
            WHEN (t.r5 > 0) THEN 'Yes'::text
            ELSE 'No'::text
        END AS dataset_released
   FROM ( SELECT u.username AS prn,
            u.name,
            max(
                CASE
                    WHEN (COALESCE(neu.entity_type_id, 0) = 1) THEN 1
                    ELSE 0
                END) AS r1,
            max(
                CASE
                    WHEN (COALESCE(neu.entity_type_id, 0) = 2) THEN 1
                    ELSE 0
                END) AS r2,
            max(
                CASE
                    WHEN (COALESCE(neu.entity_type_id, 0) = 3) THEN 1
                    ELSE 0
                END) AS r3,
            max(
                CASE
                    WHEN (COALESCE(neu.entity_type_id, 0) = 4) THEN 1
                    ELSE 0
                END) AS r4,
            max(
                CASE
                    WHEN (COALESCE(neu.entity_type_id, 0) = 5) THEN 1
                    ELSE 0
                END) AS r5
           FROM (public.t_notification_entity_user neu
             RIGHT JOIN public.t_users u ON ((neu.user_id = u.user_id)))
          GROUP BY u.username, u.name) t;


ALTER TABLE public.v_notification_entry OWNER TO d3l243;

--
-- Name: TABLE v_notification_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_notification_entry TO readaccess;

