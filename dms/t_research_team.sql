--
-- Name: t_research_team; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_research_team (
    team_id integer NOT NULL,
    team public.citext NOT NULL,
    description public.citext,
    collaborators public.citext,
    CONSTRAINT ck_t_research_team_team_name_whitespace CHECK ((public.has_whitespace_chars((team)::text, true) = false))
);


ALTER TABLE public.t_research_team OWNER TO d3l243;

--
-- Name: t_research_team_team_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_research_team ALTER COLUMN team_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_research_team_team_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_research_team pk_t_research_team; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_research_team
    ADD CONSTRAINT pk_t_research_team PRIMARY KEY (team_id);

ALTER TABLE public.t_research_team CLUSTER ON pk_t_research_team;

--
-- Name: TABLE t_research_team; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_research_team TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_research_team TO writeaccess;

