--
-- Name: v_analysis_job_and_dataset_archive_state; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_and_dataset_archive_state AS
 SELECT j.job,
        CASE
            WHEN ((j.job_state_id = 1) AND ((da.archive_state_id = ANY (ARRAY[3, 4, 10, 14, 15])) OR (da.archive_state_last_affected < (CURRENT_TIMESTAMP - '03:00:00'::interval)))) THEN (js.job_state)::text
            WHEN ((j.job_state_id = 1) AND (da.archive_state_id < 3)) THEN ((js.job_state)::text || ' (Dataset Not Archived)'::text)
            WHEN ((j.job_state_id = 1) AND (da.archive_state_id > 3)) THEN ((((js.job_state)::text || ' (Dataset '::text) || (dasn.archive_state)::text) || ')'::text)
            ELSE (js.job_state)::text
        END AS job_state,
    COALESCE(dasn.archive_state, ''::public.citext) AS dataset_archive_state,
    j.dataset_id
   FROM ((((public.t_analysis_job j
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
     JOIN public.t_dataset d ON ((j.dataset_id = d.dataset_id)))
     LEFT JOIN public.t_dataset_archive da ON ((da.dataset_id = j.dataset_id)))
     LEFT JOIN public.t_dataset_archive_state_name dasn ON ((dasn.archive_state_id = da.archive_state_id)));


ALTER TABLE public.v_analysis_job_and_dataset_archive_state OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_and_dataset_archive_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_and_dataset_archive_state TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_and_dataset_archive_state TO writeaccess;

