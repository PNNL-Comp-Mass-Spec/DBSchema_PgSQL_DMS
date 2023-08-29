--
-- Name: v_run_interval_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_interval_detail_report AS
 SELECT r.dataset_id AS id,
    r.instrument,
    r.start,
    r."interval",
    r.comment,
    (((((((((((((((((((((((((((((((('UserRemote:'::text || u.user_remote) || '%'::text) ||
        CASE
            WHEN (u.user_remote <> '0'::text) THEN ((' Proposal '::text || u.user_proposal) || ''::text)
            ELSE ''::text
        END) || '|'::text) || 'UserOnsite:'::text) || u.user_onsite) || '%'::text) ||
        CASE
            WHEN (u.user_onsite <> '0'::text) THEN ((' Proposal '::text || u.user_proposal) || ''::text)
            ELSE ''::text
        END) || '|'::text) || 'User:'::text) || u."user") || '%'::text) ||
        CASE
            WHEN (u."user" <> '0'::text) THEN ((' Proposal '::text || u.user_proposal) || ''::text)
            ELSE ''::text
        END) || '|'::text) || 'Broken:'::text) || u.broken) || '%|'::text) || 'Maintenance:'::text) || u.maintenance) || '%|'::text) || 'StaffNotAvailable:'::text) || u.staff_not_available) || '%|'::text) || 'CapDev:'::text) || u.cap_dev) || '%|'::text) || 'ResourceOwner:'::text) || u.resource_owner) || '%|'::text) || 'InstrumentAvailable:'::text) || u.instrument_available) || '%'::text) AS usage,
    r.entered,
    r.last_affected,
    r.entered_by
   FROM (public.t_run_interval r
     LEFT JOIN public.v_run_interval_usage u ON ((r.dataset_id = u.id)));


ALTER TABLE public.v_run_interval_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_run_interval_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_interval_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_run_interval_detail_report TO writeaccess;

