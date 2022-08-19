--
-- Name: t_research_team_roles; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_research_team_roles (
    role_id integer NOT NULL,
    role public.citext NOT NULL,
    description public.citext
);


ALTER TABLE public.t_research_team_roles OWNER TO d3l243;

--
-- Name: t_research_team_roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_research_team_roles ALTER COLUMN role_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_research_team_roles_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_research_team_roles pk_t_research_team_roles; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_research_team_roles
    ADD CONSTRAINT pk_t_research_team_roles PRIMARY KEY (role_id);

--
-- Name: TABLE t_research_team_roles; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_research_team_roles TO readaccess;
GRANT SELECT ON TABLE public.t_research_team_roles TO writeaccess;

