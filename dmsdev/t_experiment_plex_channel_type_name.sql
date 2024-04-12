--
-- Name: t_experiment_plex_channel_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_plex_channel_type_name (
    channel_type_id smallint NOT NULL,
    channel_type_name public.citext NOT NULL
);


ALTER TABLE public.t_experiment_plex_channel_type_name OWNER TO d3l243;

--
-- Name: t_experiment_plex_channel_type_name pk_t_experiment_plex_channel_types; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_plex_channel_type_name
    ADD CONSTRAINT pk_t_experiment_plex_channel_types PRIMARY KEY (channel_type_id);

--
-- Name: TABLE t_experiment_plex_channel_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_plex_channel_type_name TO readaccess;
GRANT SELECT ON TABLE public.t_experiment_plex_channel_type_name TO writeaccess;

