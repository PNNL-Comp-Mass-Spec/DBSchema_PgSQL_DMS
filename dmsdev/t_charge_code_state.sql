--
-- Name: t_charge_code_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_charge_code_state (
    charge_code_state smallint NOT NULL,
    charge_code_state_name public.citext NOT NULL
);


ALTER TABLE public.t_charge_code_state OWNER TO d3l243;

--
-- Name: t_charge_code_state pk_t_charge_code_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_charge_code_state
    ADD CONSTRAINT pk_t_charge_code_state PRIMARY KEY (charge_code_state);

ALTER TABLE public.t_charge_code_state CLUSTER ON pk_t_charge_code_state;

--
-- Name: TABLE t_charge_code_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_charge_code_state TO readaccess;
GRANT SELECT ON TABLE public.t_charge_code_state TO writeaccess;

