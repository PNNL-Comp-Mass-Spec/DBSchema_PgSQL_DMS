--
-- Name: t_research_team; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_research_team (
    team_id integer NOT NULL,
    team public.citext NOT NULL,
    description public.citext,
    collaborators public.citext
);


ALTER TABLE public.t_research_team OWNER TO d3l243;

--
-- Name: t_research_team pk_t_research_team; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_research_team
    ADD CONSTRAINT pk_t_research_team PRIMARY KEY (team_id);

--
-- Name: TABLE t_research_team; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_research_team TO readaccess;

