--
-- Name: v_service_use_admin_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_use_admin_report AS
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
    u.report_id
   FROM ((((((cc.t_service_use u
     JOIN cc.t_service_use_report rep ON ((rep.report_id = u.report_id)))
     JOIN cc.t_service_type t ON ((t.service_type_id = u.service_type_id)))
     JOIN public.t_dataset ds ON ((u.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((dsrating.dataset_rating_id = ds.dataset_rating_id)))
     LEFT JOIN public.t_charge_code public ON ((public.charge_code OPERATOR(public.=) u.charge_code)))
     LEFT JOIN public.t_cached_dataset_stats cds ON ((u.dataset_id = cds.dataset_id)));


ALTER VIEW public.v_service_use_admin_report OWNER TO d3l243;

--
-- Name: TABLE v_service_use_admin_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_use_admin_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_use_admin_report TO writeaccess;

