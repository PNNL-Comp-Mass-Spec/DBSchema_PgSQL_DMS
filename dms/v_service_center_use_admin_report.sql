--
-- Name: v_service_center_use_admin_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_center_use_admin_report AS
 SELECT u.entry_id,
    u.dataset_id,
    cds.instrument,
    u.charge_code,
    u.service_type_id,
    t.service_type,
    u.transaction_date,
    u.transaction_units,
    u.is_held,
    u.comment,
    dsrating.dataset_rating,
    u.report_id,
        CASE
            WHEN ((rep.report_state_id = ANY (ARRAY[1, 2])) AND (ds.svc_center_report_state_id = 3)) THEN 'Submitting to service center'::public.citext
            WHEN ((rep.report_state_id = ANY (ARRAY[1, 2])) AND (ds.svc_center_report_state_id = 5)) THEN 'Refunding to service center'::public.citext
            ELSE repstate.svc_center_report_state
        END AS dataset_svc_center_state,
    ds.comment AS dataset_comment,
    rep.report_state_id
   FROM ((((((svc.t_service_use u
     JOIN svc.t_service_use_report rep ON ((rep.report_id = u.report_id)))
     JOIN svc.t_service_type t ON ((t.service_type_id = u.service_type_id)))
     JOIN public.t_dataset ds ON ((u.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((dsrating.dataset_rating_id = ds.dataset_rating_id)))
     JOIN public.t_dataset_svc_center_report_state repstate ON ((repstate.svc_center_report_state_id = ds.svc_center_report_state_id)))
     LEFT JOIN public.t_cached_dataset_stats cds ON ((u.dataset_id = cds.dataset_id)));


ALTER VIEW public.v_service_center_use_admin_report OWNER TO d3l243;

--
-- Name: TABLE v_service_center_use_admin_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_center_use_admin_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_center_use_admin_report TO writeaccess;

