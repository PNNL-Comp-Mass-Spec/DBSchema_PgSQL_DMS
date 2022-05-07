--
-- Name: t_eus_proposal_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_proposal_users (
    proposal_id public.citext NOT NULL,
    person_id integer NOT NULL,
    of_dms_interest character(1) DEFAULT 'Y'::bpchar NOT NULL,
    state_id smallint DEFAULT 1 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_eus_proposal_users OWNER TO d3l243;

--
-- Name: t_eus_proposal_users pk_t_eus_proposal_users; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_proposal_users
    ADD CONSTRAINT pk_t_eus_proposal_users PRIMARY KEY (proposal_id, person_id);

--
-- Name: t_eus_proposal_users fk_t_eus_proposal_users_t_eus_proposals; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_proposal_users
    ADD CONSTRAINT fk_t_eus_proposal_users_t_eus_proposals FOREIGN KEY (proposal_id) REFERENCES public.t_eus_proposals(proposal_id);

--
-- Name: t_eus_proposal_users fk_t_eus_proposal_users_t_eus_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_proposal_users
    ADD CONSTRAINT fk_t_eus_proposal_users_t_eus_users FOREIGN KEY (person_id) REFERENCES public.t_eus_users(person_id);

--
-- Name: TABLE t_eus_proposal_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_proposal_users TO readaccess;

