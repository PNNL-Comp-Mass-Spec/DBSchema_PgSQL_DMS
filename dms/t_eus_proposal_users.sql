--
-- Name: t_eus_proposal_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_proposal_users (
    proposal_id public.citext NOT NULL,
    person_id integer NOT NULL,
    of_dms_interest character(1) NOT NULL,
    state_id smallint NOT NULL,
    last_affected timestamp without time zone
);


ALTER TABLE public.t_eus_proposal_users OWNER TO d3l243;

--
-- Name: t_eus_proposal_users pk_t_eus_proposal_users; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_proposal_users
    ADD CONSTRAINT pk_t_eus_proposal_users PRIMARY KEY (proposal_id, person_id);

--
-- Name: TABLE t_eus_proposal_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_proposal_users TO readaccess;

