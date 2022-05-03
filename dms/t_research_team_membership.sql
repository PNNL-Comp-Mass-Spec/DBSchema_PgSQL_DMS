--
-- Name: t_research_team_membership; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_research_team_membership (
    team_id integer NOT NULL,
    role_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.t_research_team_membership OWNER TO d3l243;

--
-- Name: t_research_team_membership pk_t_research_team_membership; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_research_team_membership
    ADD CONSTRAINT pk_t_research_team_membership PRIMARY KEY (team_id, role_id, user_id);

--
-- Name: TABLE t_research_team_membership; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_research_team_membership TO readaccess;

