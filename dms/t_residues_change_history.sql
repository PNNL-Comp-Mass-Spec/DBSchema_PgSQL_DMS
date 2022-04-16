--
-- Name: t_residues_change_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_residues_change_history (
    event_id integer NOT NULL,
    residue_id integer NOT NULL,
    residue_symbol character(1) NOT NULL,
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
    entered timestamp without time zone NOT NULL,
    entered_by public.citext
);


ALTER TABLE public.t_residues_change_history OWNER TO d3l243;

--
-- Name: TABLE t_residues_change_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_residues_change_history TO readaccess;

