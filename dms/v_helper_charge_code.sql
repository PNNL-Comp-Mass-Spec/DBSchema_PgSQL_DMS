--
-- Name: v_helper_charge_code; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_charge_code AS
 SELECT cc.charge_code,
    cca.activation_state_name AS state,
    cc.wbs_title AS wbs,
    cc.charge_code_title AS title,
    cc.sub_account_title AS sub_account,
    cc.usage_sample_prep,
    cc.usage_requested_run,
    COALESCE((dmsuser.username)::text, ('D'::text || (cc.resp_prn)::text)) AS owner_prn,
    dmsuser.name AS owner_name,
    cc.setup_date,
    cc.sort_key,
    cc.activation_state
   FROM ((public.t_charge_code cc
     JOIN public.t_charge_code_activation_state cca ON ((cc.activation_state = cca.activation_state)))
     LEFT JOIN public.v_charge_code_owner_dms_user_map dmsuser ON ((cc.charge_code OPERATOR(public.=) dmsuser.charge_code)))
  WHERE (cc.charge_code_state > 0);


ALTER TABLE public.v_helper_charge_code OWNER TO d3l243;

--
-- Name: TABLE v_helper_charge_code; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_charge_code TO readaccess;
GRANT SELECT ON TABLE public.v_helper_charge_code TO writeaccess;

