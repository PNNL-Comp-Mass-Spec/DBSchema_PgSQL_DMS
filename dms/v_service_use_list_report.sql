--
-- Name: v_service_use; Type: VIEW; Schema: cc; Owner: d3l243
--

CREATE VIEW cc.v_service_use AS
 SELECT svcuse.report_id,
    svcuse.ticket_number,
    cc.sub_account,
    svcuse.service_type_id AS type_of_service,
    svcuserep.requestor_employee_id,
    svcuse.charge_code,
    svcuse.transaction_date,
    svcuse.transaction_units,
    svcuse.is_held,
    svcuse.comment
   FROM ((cc.t_service_use svcuse
     JOIN cc.t_service_use_report svcuserep ON ((svcuserep.report_id = svcuse.report_id)))
     LEFT JOIN public.t_charge_code cc ON ((cc.charge_code OPERATOR(public.=) svcuse.charge_code)));


ALTER VIEW cc.v_service_use OWNER TO d3l243;

