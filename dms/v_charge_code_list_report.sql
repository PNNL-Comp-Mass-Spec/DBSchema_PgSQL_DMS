--
-- Name: v_charge_code_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_charge_code_list_report AS
 SELECT cc.charge_code,
    cca.activation_state_name AS state,
    cc.wbs_title AS wbs,
    cc.charge_code_title AS title,
    cc.sub_account_title AS sub_account,
    cc.usage_sample_prep,
    cc.usage_requested_run,
    (COALESCE((dmsuser.username)::text, ('D'::text || (cc.resp_username)::text)))::public.citext AS owner_username,
    dmsuser.name AS owner_name,
    cc.setup_date,
    cc.sort_key,
    cc.activation_state
   FROM ((public.t_charge_code cc
     JOIN public.t_charge_code_activation_state cca ON ((cc.activation_state = cca.activation_state)))
     LEFT JOIN public.v_charge_code_owner_dms_user_map dmsuser ON ((cc.charge_code OPERATOR(public.=) dmsuser.charge_code)));


ALTER TABLE public.v_charge_code_list_report OWNER TO d3l243;

--
-- Name: TABLE v_charge_code_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_charge_code_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_charge_code_list_report TO writeaccess;

