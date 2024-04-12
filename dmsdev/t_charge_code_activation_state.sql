--
-- Name: t_charge_code_activation_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_charge_code_activation_state (
    activation_state smallint NOT NULL,
    activation_state_name public.citext NOT NULL
);


ALTER TABLE public.t_charge_code_activation_state OWNER TO d3l243;

--
-- Name: t_charge_code_activation_state pk_t_charge_code_activation_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_charge_code_activation_state
    ADD CONSTRAINT pk_t_charge_code_activation_state PRIMARY KEY (activation_state);

ALTER TABLE public.t_charge_code_activation_state CLUSTER ON pk_t_charge_code_activation_state;

--
-- Name: TABLE t_charge_code_activation_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_charge_code_activation_state TO readaccess;
GRANT SELECT ON TABLE public.t_charge_code_activation_state TO writeaccess;

