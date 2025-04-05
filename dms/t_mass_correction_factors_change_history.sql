--
-- Name: t_mass_correction_factors_change_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mass_correction_factors_change_history (
    event_id integer NOT NULL,
    mass_correction_id integer NOT NULL,
    mass_correction_tag public.citext NOT NULL,
    description public.citext,
    monoisotopic_mass double precision NOT NULL,
    average_mass double precision,
    affected_atom public.citext NOT NULL,
    original_source public.citext,
    original_source_name public.citext,
    alternative_name public.citext,
    empirical_formula public.citext,
    monoisotopic_mass_change double precision,
    average_mass_change double precision,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_mass_correction_factors_change_history OWNER TO d3l243;

--
-- Name: t_mass_correction_factors_change_history_event_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_mass_correction_factors_change_history ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_mass_correction_factors_change_history_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_mass_correction_factors_change_history pk_t_mass_correction_factors_change_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mass_correction_factors_change_history
    ADD CONSTRAINT pk_t_mass_correction_factors_change_history PRIMARY KEY (event_id);

ALTER TABLE public.t_mass_correction_factors_change_history CLUSTER ON pk_t_mass_correction_factors_change_history;

--
-- Name: TABLE t_mass_correction_factors_change_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mass_correction_factors_change_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_mass_correction_factors_change_history TO writeaccess;

