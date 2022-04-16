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
-- Name: TABLE t_research_team_roles; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_research_team_roles TO readaccess;

