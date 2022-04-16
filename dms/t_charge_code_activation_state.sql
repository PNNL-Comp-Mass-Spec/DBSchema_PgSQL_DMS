--
-- Name: t_charge_code_activation_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_charge_code_activation_state (
    activation_state smallint NOT NULL,
    activation_state_name public.citext NOT NULL
);


ALTER TABLE public.t_charge_code_activation_state OWNER TO d3l243;

--
-- Name: TABLE t_charge_code_activation_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_charge_code_activation_state TO readaccess;

