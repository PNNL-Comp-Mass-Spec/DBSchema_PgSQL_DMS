--
-- Name: v_service_center_use_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_center_use_entry AS
 SELECT entry_id AS id,
    report_id,
    dataset_id,
    charge_code,
    service_type_id,
    transaction_date,
    transaction_units,
    is_held,
    comment,
    ticket_number
   FROM svc.t_service_use;


ALTER VIEW public.v_service_center_use_entry OWNER TO d3l243;

--
-- Name: TABLE v_service_center_use_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_center_use_entry TO readaccess;
GRANT SELECT ON TABLE public.v_service_center_use_entry TO writeaccess;

