--
-- Name: t_residues_change_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_residues_change_history (
    event_id integer NOT NULL,
    residue_id integer NOT NULL,
    residue_symbol public.citext NOT NULL,
    description public.citext NOT NULL,
    average_mass double precision NOT NULL,
    monoisotopic_mass double precision NOT NULL,
    num_c smallint NOT NULL,
    num_h smallint NOT NULL,
    num_n smallint NOT NULL,
    num_o smallint NOT NULL,
    num_s smallint NOT NULL,
    monoisotopic_mass_change double precision,
    average_mass_change double precision,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_residues_change_history OWNER TO d3l243;

--
-- Name: t_residues_change_history_event_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_residues_change_history ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_residues_change_history_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_residues_change_history pk_t_residues_change_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_residues_change_history
    ADD CONSTRAINT pk_t_residues_change_history PRIMARY KEY (event_id);

ALTER TABLE public.t_residues_change_history CLUSTER ON pk_t_residues_change_history;

--
-- Name: TABLE t_residues_change_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_residues_change_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_residues_change_history TO writeaccess;

