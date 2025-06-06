--
-- Name: t_eus_proposals; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_proposals (
    proposal_id public.citext DEFAULT ''::public.citext NOT NULL,
    title public.citext,
    state_id integer DEFAULT 1 NOT NULL,
    import_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    proposal_type public.citext,
    proposal_start_date timestamp without time zone,
    proposal_end_date timestamp without time zone,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    numeric_id integer GENERATED ALWAYS AS (public.extract_integer((proposal_id)::text)) STORED,
    proposal_id_auto_supersede public.citext
);


ALTER TABLE public.t_eus_proposals OWNER TO d3l243;

--
-- Name: t_eus_proposals pk_t_eus_proposals; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_proposals
    ADD CONSTRAINT pk_t_eus_proposals PRIMARY KEY (proposal_id);

ALTER TABLE public.t_eus_proposals CLUSTER ON pk_t_eus_proposals;

--
-- Name: ix_t_eus_proposals; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_eus_proposals ON public.t_eus_proposals USING btree (state_id);

--
-- Name: ix_t_eus_proposals_type; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_eus_proposals_type ON public.t_eus_proposals USING btree (proposal_type);

--
-- Name: t_eus_proposals fk_t_eus_proposals_t_eus_proposal_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_proposals
    ADD CONSTRAINT fk_t_eus_proposals_t_eus_proposal_state_name FOREIGN KEY (state_id) REFERENCES public.t_eus_proposal_state_name(state_id);

--
-- Name: TABLE t_eus_proposals; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_proposals TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_eus_proposals TO writeaccess;

