--
-- Name: t_experiment_plex_channel_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_plex_channel_type_name (
    channel_type_id smallint NOT NULL,
    channel_type_name public.citext NOT NULL
);


ALTER TABLE public.t_experiment_plex_channel_type_name OWNER TO d3l243;

--
-- Name: TABLE t_experiment_plex_channel_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_plex_channel_type_name TO readaccess;

