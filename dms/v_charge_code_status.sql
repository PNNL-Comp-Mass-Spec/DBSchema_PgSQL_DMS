--
-- Name: v_charge_code_status; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_charge_code_status AS
 SELECT cc.charge_code,
    cc.charge_code_state,
    ccs.charge_code_state_name,
    cc.activation_state,
    cca.activation_state_name
   FROM ((public.t_charge_code cc
     JOIN public.t_charge_code_activation_state cca ON ((cc.activation_state = cca.activation_state)))
     JOIN public.t_charge_code_state ccs ON ((cc.charge_code_state = ccs.charge_code_state)));


ALTER TABLE public.v_charge_code_status OWNER TO d3l243;

--
-- Name: TABLE v_charge_code_status; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_charge_code_status TO readaccess;

