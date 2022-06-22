--
-- Name: t_maxquant_mods; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_maxquant_mods (
    mod_id integer NOT NULL,
    mod_title public.citext NOT NULL,
    mod_position public.citext DEFAULT 'anywhere'::public.citext NOT NULL,
    mass_correction_id integer,
    composition public.citext,
    isobaric_mod_ion_number smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.t_maxquant_mods OWNER TO d3l243;

--
-- Name: t_maxquant_mods_mod_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_maxquant_mods ALTER COLUMN mod_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_maxquant_mods_mod_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_maxquant_mods pk_t_maxquant_mods; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_maxquant_mods
    ADD CONSTRAINT pk_t_maxquant_mods PRIMARY KEY (mod_id);

--
-- Name: t_maxquant_mods fk_t_maxquant_mods_t_mass_correction_factors; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_maxquant_mods
    ADD CONSTRAINT fk_t_maxquant_mods_t_mass_correction_factors FOREIGN KEY (mass_correction_id) REFERENCES public.t_mass_correction_factors(mass_correction_id);

--
-- Name: TABLE t_maxquant_mods; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_maxquant_mods TO readaccess;

