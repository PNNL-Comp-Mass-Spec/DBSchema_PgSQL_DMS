--
-- Name: t_spectral_library; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_spectral_library (
    library_id integer NOT NULL,
    library_name public.citext NOT NULL,
    library_state_id integer NOT NULL,
    library_type_id integer NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    source_job integer,
    comment public.citext DEFAULT ''::public.citext NOT NULL,
    server_share public.citext DEFAULT ''::public.citext NOT NULL,
    protein_collection_list public.citext DEFAULT 'na'::public.citext NOT NULL,
    organism_db_file public.citext DEFAULT 'na'::public.citext NOT NULL,
    fragment_ion_mz_min real DEFAULT 0 NOT NULL,
    fragment_ion_mz_max real DEFAULT 0 NOT NULL,
    trim_n_terminal_met boolean DEFAULT false NOT NULL,
    cleavage_specificity public.citext DEFAULT ''::public.citext NOT NULL,
    missed_cleavages integer DEFAULT 0 NOT NULL,
    peptide_length_min smallint DEFAULT 0 NOT NULL,
    peptide_length_max smallint DEFAULT 0 NOT NULL,
    precursor_mz_min real DEFAULT 0 NOT NULL,
    precursor_mz_max real DEFAULT 0 NOT NULL,
    precursor_charge_min smallint DEFAULT 0 NOT NULL,
    precursor_charge_max smallint DEFAULT 0 NOT NULL,
    static_cys_carbamidomethyl boolean DEFAULT false NOT NULL,
    static_mods public.citext DEFAULT ''::public.citext NOT NULL,
    dynamic_mods public.citext DEFAULT ''::public.citext NOT NULL,
    max_dynamic_mods smallint DEFAULT 0 NOT NULL,
    settings_hash public.citext DEFAULT ''::text NOT NULL
);


ALTER TABLE public.t_spectral_library OWNER TO d3l243;

--
-- Name: t_spectral_library_library_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_spectral_library ALTER COLUMN library_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_spectral_library_library_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_spectral_library pk_t_spectral_library; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_spectral_library
    ADD CONSTRAINT pk_t_spectral_library PRIMARY KEY (library_id);

--
-- Name: ix_t_spectral_library_library_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_spectral_library_library_name ON public.t_spectral_library USING btree (library_name);

--
-- Name: ix_t_spectral_library_library_name_settings_hash; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_spectral_library_library_name_settings_hash ON public.t_spectral_library USING btree (library_name, settings_hash);

--
-- Name: t_spectral_library fk_t_spectral_library_t_spectral_library_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_spectral_library
    ADD CONSTRAINT fk_t_spectral_library_t_spectral_library_state FOREIGN KEY (library_state_id) REFERENCES public.t_spectral_library_state(library_state_id);

--
-- Name: t_spectral_library fk_t_spectral_library_t_spectral_library_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_spectral_library
    ADD CONSTRAINT fk_t_spectral_library_t_spectral_library_type FOREIGN KEY (library_type_id) REFERENCES public.t_spectral_library_type(library_type_id);

--
-- Name: TABLE t_spectral_library; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_spectral_library TO readaccess;
GRANT SELECT ON TABLE public.t_spectral_library TO writeaccess;

