--
-- Name: t_instrument_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_state_name (
    state_name public.citext NOT NULL,
    description public.citext NOT NULL
);


ALTER TABLE public.t_instrument_state_name OWNER TO d3l243;

--
-- Name: t_instrument_state_name pk_t_instrument_state_id; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_state_name
    ADD CONSTRAINT pk_t_instrument_state_id PRIMARY KEY (state_name);

ALTER TABLE public.t_instrument_state_name CLUSTER ON pk_t_instrument_state_id;

--
-- Name: TABLE t_instrument_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_state_name TO readaccess;
GRANT SELECT ON TABLE public.t_instrument_state_name TO writeaccess;

