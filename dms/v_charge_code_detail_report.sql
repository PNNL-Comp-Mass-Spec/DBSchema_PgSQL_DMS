--
-- Name: v_charge_code_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_charge_code_detail_report AS
 SELECT cc.charge_code,
    COALESCE(cca.activation_state_name, 'Invalid'::public.citext) AS state,
    cc.wbs_title AS wbs,
    cc.charge_code_title AS title,
    cc.sub_account AS sub_account_id,
    cc.sub_account_title AS sub_account,
    cc.sub_account_effective_date,
    cc.inactive_date_most_recent,
    cc.inactive_date,
    cc.sub_account_inactive_date,
    cc.deactivated,
    cc.setup_date,
    cc.usage_sample_prep,
    cc.usage_requested_run,
    cc.resp_prn,
    cc.resp_hid,
    dmsuser.username AS owner_prn,
    dmsuser.name AS owner_name,
    cc.auto_defined,
    cc.charge_code_state,
    cc.last_affected,
    cca.activation_state AS "#WPActivationState"
   FROM ((public.t_charge_code cc
     JOIN public.t_charge_code_activation_state cca ON ((cc.activation_state = cca.activation_state)))
     LEFT JOIN public.v_charge_code_owner_dms_user_map dmsuser ON ((cc.charge_code OPERATOR(public.=) dmsuser.charge_code)));


ALTER TABLE public.v_charge_code_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_charge_code_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_charge_code_detail_report TO readaccess;

