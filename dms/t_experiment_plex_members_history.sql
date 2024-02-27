--
-- Name: t_experiment_plex_members_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_plex_members_history (
    entry_id integer NOT NULL,
    plex_exp_id integer NOT NULL,
    channel smallint NOT NULL,
    exp_id integer NOT NULL,
    state smallint NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_experiment_plex_members_history OWNER TO d3l243;

--
-- Name: t_experiment_plex_members_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_experiment_plex_members_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_experiment_plex_members_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_experiment_plex_members_history pk_t_experiment_plex_members_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_plex_members_history
    ADD CONSTRAINT pk_t_experiment_plex_members_history PRIMARY KEY (entry_id);

--
-- Name: TABLE t_experiment_plex_members_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_plex_members_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_experiment_plex_members_history TO writeaccess;

