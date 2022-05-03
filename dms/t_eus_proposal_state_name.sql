--
-- Name: t_eus_proposal_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_proposal_state_name (
    eus_project_id integer NOT NULL,
    eus_project public.citext
);


ALTER TABLE public.t_eus_proposal_state_name OWNER TO d3l243;

--
-- Name: t_eus_proposal_state_name pk_t_eus_proposal_state_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_proposal_state_name
    ADD CONSTRAINT pk_t_eus_proposal_state_name PRIMARY KEY (eus_project_id);

--
-- Name: TABLE t_eus_proposal_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_proposal_state_name TO readaccess;

