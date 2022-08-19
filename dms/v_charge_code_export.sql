--
-- Name: v_charge_code_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_charge_code_export AS
 SELECT cc.charge_code,
    cca.activation_state_name AS state,
    cc.sub_account_title AS subaccount,
    cc.wbs_title AS workbreakdownstructure,
    cc.charge_code_title AS title,
    cc.usage_sample_prep,
    cc.usage_requested_run,
    COALESCE((dmsuser.username)::text, ('D'::text || (cc.resp_prn)::text)) AS owner_prn,
    dmsuser.name AS owner_name,
    cc.setup_date,
    cc.sort_key AS sortkey
   FROM ((public.t_charge_code cc
     JOIN public.t_charge_code_activation_state cca ON ((cc.activation_state = cca.activation_state)))
     LEFT JOIN public.v_charge_code_owner_dms_user_map dmsuser ON ((cc.charge_code OPERATOR(public.=) dmsuser.charge_code)));


ALTER TABLE public.v_charge_code_export OWNER TO d3l243;

--
-- Name: VIEW v_charge_code_export; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_charge_code_export IS 'Charge_Code is also known as "Work Package"';

--
-- Name: TABLE v_charge_code_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_charge_code_export TO readaccess;
GRANT SELECT ON TABLE public.v_charge_code_export TO writeaccess;

