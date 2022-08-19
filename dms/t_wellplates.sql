--
-- Name: t_wellplates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_wellplates (
    wellplate_id integer NOT NULL,
    wellplate public.citext NOT NULL,
    description public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_t_wellplates_well_plate_name_white_space CHECK ((public.has_whitespace_chars((wellplate)::text, 1) = false))
);


ALTER TABLE public.t_wellplates OWNER TO d3l243;

--
-- Name: t_wellplates_wellplate_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_wellplates ALTER COLUMN wellplate_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_wellplates_wellplate_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_wellplates ix_t_wellplates_unique_wellplate; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_wellplates
    ADD CONSTRAINT ix_t_wellplates_unique_wellplate UNIQUE (wellplate);

--
-- Name: t_wellplates pk_t_wellplates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_wellplates
    ADD CONSTRAINT pk_t_wellplates PRIMARY KEY (wellplate_id);

--
-- Name: TABLE t_wellplates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_wellplates TO readaccess;
GRANT SELECT ON TABLE public.t_wellplates TO writeaccess;

