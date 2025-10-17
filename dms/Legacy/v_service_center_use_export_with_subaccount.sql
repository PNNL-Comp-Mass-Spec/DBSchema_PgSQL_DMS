--
-- Name: v_service_center_use_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_center_use_export AS
 SELECT u.ticket_number,
    cc.sub_account,
    u.service_type_id,
    rep.requester_employee_id,
    u.charge_code,
    u.transaction_date,
    u.transaction_units,
    u.is_held,
    u.comment,
    inst.instrument,
    u.dataset_id,
    u.report_id
   FROM ((((((svc.t_service_use u
     JOIN svc.t_service_use_report rep ON ((rep.report_id = u.report_id)))
     JOIN svc.t_service_type t ON ((t.service_type_id = u.service_type_id)))
     LEFT JOIN public.t_charge_code cc ON ((cc.charge_code OPERATOR(public.=) u.charge_code)))
     LEFT JOIN public.t_cached_dataset_stats cds ON ((u.dataset_id = cds.dataset_id)))
     LEFT JOIN public.t_dataset ds ON ((u.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
  WHERE (NOT (u.service_type_id = ANY (ARRAY[0, 1, 25])));


ALTER VIEW public.v_service_center_use_export OWNER TO d3l243;

--
-- Name: TABLE v_service_center_use_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_center_use_export TO readaccess;
GRANT SELECT ON TABLE public.v_service_center_use_export TO writeaccess;

