--
-- Name: t_campaign; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_campaign (
    campaign_id integer NOT NULL,
    campaign public.citext NOT NULL,
    project public.citext NOT NULL,
    project_mgr_username public.citext,
    pi_username public.citext,
    comment public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    technical_lead public.citext,
    state public.citext DEFAULT 'Active'::public.citext NOT NULL,
    description public.citext,
    external_links public.citext,
    team_members public.citext,
    epr_list public.citext,
    eus_proposal_list public.citext,
    organisms public.citext,
    experiment_prefixes public.citext,
    research_team integer,
    data_release_restriction_id integer DEFAULT 0 NOT NULL,
    fraction_emsl_funded numeric(3,2) DEFAULT 0 NOT NULL,
    eus_usage_type_id smallint DEFAULT 1 NOT NULL,
    CONSTRAINT ck_t_campaign_campaign_name_whitespace CHECK ((public.has_whitespace_chars((campaign)::text, true) = false))
);


ALTER TABLE public.t_campaign OWNER TO d3l243;

--
-- Name: t_campaign_campaign_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_campaign ALTER COLUMN campaign_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_campaign_campaign_id_seq
    START WITH 2100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_campaign pk_t_campaign; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_campaign
    ADD CONSTRAINT pk_t_campaign PRIMARY KEY (campaign_id);

--
-- Name: ix_t_campaign_campaign; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_campaign_campaign ON public.t_campaign USING btree (campaign);

--
-- Name: ix_t_campaign_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_campaign_created ON public.t_campaign USING btree (created);

--
-- Name: t_campaign trig_t_campaign_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_campaign_after_delete AFTER DELETE ON public.t_campaign REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_campaign_after_delete();

--
-- Name: t_campaign trig_t_campaign_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_campaign_after_insert AFTER INSERT ON public.t_campaign REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_campaign_after_insert();

--
-- Name: t_campaign trig_t_campaign_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_campaign_after_update AFTER UPDATE ON public.t_campaign REFERENCING OLD TABLE AS deleted NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_campaign_after_update();

--
-- Name: t_campaign fk_t_campaign_t_data_release_restrictions; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_campaign
    ADD CONSTRAINT fk_t_campaign_t_data_release_restrictions FOREIGN KEY (data_release_restriction_id) REFERENCES public.t_data_release_restrictions(release_restriction_id);

--
-- Name: t_campaign fk_t_campaign_t_eus_usage_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_campaign
    ADD CONSTRAINT fk_t_campaign_t_eus_usage_type FOREIGN KEY (eus_usage_type_id) REFERENCES public.t_eus_usage_type(eus_usage_type_id);

--
-- Name: t_campaign fk_t_campaign_t_research_team; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_campaign
    ADD CONSTRAINT fk_t_campaign_t_research_team FOREIGN KEY (research_team) REFERENCES public.t_research_team(team_id);

--
-- Name: TABLE t_campaign; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_campaign TO readaccess;
GRANT SELECT ON TABLE public.t_campaign TO writeaccess;

