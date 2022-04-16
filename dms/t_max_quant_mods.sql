--
-- Name: t_max_quant_mods; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_max_quant_mods (
    mod_id integer NOT NULL,
    mod_title public.citext NOT NULL,
    mod_position public.citext NOT NULL,
    mass_correction_id integer,
    composition public.citext,
    isobaric_mod_ion_number smallint NOT NULL
);


ALTER TABLE public.t_max_quant_mods OWNER TO d3l243;

--
-- Name: TABLE t_max_quant_mods; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_max_quant_mods TO readaccess;

