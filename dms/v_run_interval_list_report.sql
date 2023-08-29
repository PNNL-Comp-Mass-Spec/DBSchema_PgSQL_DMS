--
-- Name: v_run_interval_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_interval_list_report AS
 SELECT r.dataset_id AS id,
    r.instrument,
    r.start,
    r."interval",
    r.comment,
    (u.user_remote ||
        CASE
            WHEN (u.user_remote <> '0'::text) THEN ((' (Proposal '::text || u.user_proposal) || ')'::text)
            ELSE ''::text
        END) AS user_remote,
    (u.user_onsite ||
        CASE
            WHEN (u.user_onsite <> '0'::text) THEN ((' (Proposal '::text || u.user_proposal) || ')'::text)
            ELSE ''::text
        END) AS user_onsite,
    (u."user" ||
        CASE
            WHEN (u."user" <> '0'::text) THEN ((' (Proposal '::text || u.user_proposal) || ')'::text)
            ELSE ''::text
        END) AS "user",
    u.broken,
    u.maintenance,
    u.staff_not_available,
    u.cap_dev,
    u.resource_owner,
    u.instrument_available,
    r.entered,
    r.last_affected,
    r.entered_by
   FROM (public.t_run_interval r
     LEFT JOIN public.v_run_interval_usage u ON ((r.dataset_id = u.id)));


ALTER TABLE public.v_run_interval_list_report OWNER TO d3l243;

--
-- Name: TABLE v_run_interval_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_interval_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_run_interval_list_report TO writeaccess;

