--
-- Name: t_experiment_plex_members_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_plex_members_history (
    entry_id integer NOT NULL,
    plex_exp_id integer NOT NULL,
    channel smallint NOT NULL,
    exp_id integer NOT NULL,
    state smallint NOT NULL,
    entered timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_experiment_plex_members_history OWNER TO d3l243;

--
-- Name: TABLE t_experiment_plex_members_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_plex_members_history TO readaccess;

