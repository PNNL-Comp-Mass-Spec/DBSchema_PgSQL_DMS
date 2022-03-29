--
-- Name: t_unimod_mods; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_unimod_mods (
    unimod_id integer NOT NULL,
    name public.citext NOT NULL,
    full_name public.citext NOT NULL,
    alternate_names public.citext,
    notes public.citext,
    mono_mass real NOT NULL,
    avg_mass real NOT NULL,
    composition public.citext NOT NULL,
    date_posted timestamp without time zone NOT NULL,
    date_modified timestamp without time zone NOT NULL,
    approved smallint NOT NULL,
    poster_username public.citext,
    poster_group public.citext,
    url public.citext
);


ALTER TABLE ont.t_unimod_mods OWNER TO d3l243;

--
-- Name: t_unimod_mods pk_t_unimod_mods; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_unimod_mods
    ADD CONSTRAINT pk_t_unimod_mods PRIMARY KEY (unimod_id);

