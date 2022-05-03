--
-- Name: t_campaign; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_campaign (
    campaign_id integer NOT NULL,
    campaign public.citext NOT NULL,
    project public.citext NOT NULL,
    project_mgr_prn public.citext,
    pi_prn public.citext,
    comment public.citext,
    created timestamp without time zone NOT NULL,
    technical_lead public.citext,
    state public.citext NOT NULL,
    description public.citext,
    external_links public.citext,
    team_members public.citext,
    epr_list public.citext,
    eus_proposal_list public.citext,
    organisms public.citext,
    experiment_prefixes public.citext,
    research_team integer,
    data_release_restrictions integer NOT NULL,
    fraction_emsl_funded numeric(3,2) NOT NULL,
    eus_usage_type_id smallint NOT NULL
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
-- Name: TABLE t_campaign; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_campaign TO readaccess;

