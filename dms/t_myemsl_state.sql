--
-- Name: t_myemsl_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_myemsl_state (
    myemsl_state smallint NOT NULL,
    myemsl_state_name public.citext
);


ALTER TABLE public.t_myemsl_state OWNER TO d3l243;

--
-- Name: t_myemsl_state pk_t_myemsl_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_myemsl_state
    ADD CONSTRAINT pk_t_myemsl_state PRIMARY KEY (myemsl_state);

--
-- Name: TABLE t_myemsl_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_myemsl_state TO readaccess;

