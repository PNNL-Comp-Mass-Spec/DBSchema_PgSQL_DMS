--
-- Name: t_experiment_plex_members; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_plex_members (
    plex_exp_id integer NOT NULL,
    channel smallint NOT NULL,
    exp_id integer NOT NULL,
    channel_type_id smallint NOT NULL,
    comment public.citext,
    entered timestamp without time zone NOT NULL
);


ALTER TABLE public.t_experiment_plex_members OWNER TO d3l243;

--
-- Name: TABLE t_experiment_plex_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_plex_members TO readaccess;

