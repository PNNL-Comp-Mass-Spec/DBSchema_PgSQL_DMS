--
-- Name: t_cached_instrument_usage_by_proposal; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_instrument_usage_by_proposal (
    instrument_group public.citext NOT NULL,
    eus_proposal_id public.citext NOT NULL,
    actual_hours double precision
);


ALTER TABLE public.t_cached_instrument_usage_by_proposal OWNER TO d3l243;

--
-- Name: t_cached_instrument_usage_by_proposal pk_t_cached_instrument_usage_by_proposal; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_instrument_usage_by_proposal
    ADD CONSTRAINT pk_t_cached_instrument_usage_by_proposal PRIMARY KEY (instrument_group, eus_proposal_id);

--
-- Name: t_cached_instrument_usage_by_proposal fk_t_cached_instrument_usage_by_proposal_t_eus_proposals; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_instrument_usage_by_proposal
    ADD CONSTRAINT fk_t_cached_instrument_usage_by_proposal_t_eus_proposals FOREIGN KEY (eus_proposal_id) REFERENCES public.t_eus_proposals(proposal_id);

--
-- Name: t_cached_instrument_usage_by_proposal fk_t_cached_instrument_usage_by_proposal_t_instrument_group; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_instrument_usage_by_proposal
    ADD CONSTRAINT fk_t_cached_instrument_usage_by_proposal_t_instrument_group FOREIGN KEY (instrument_group) REFERENCES public.t_instrument_group(instrument_group);

--
-- Name: TABLE t_cached_instrument_usage_by_proposal; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_instrument_usage_by_proposal TO readaccess;

