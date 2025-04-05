--
-- Name: t_spectral_library_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_spectral_library_type (
    library_type_id integer NOT NULL,
    library_type public.citext NOT NULL,
    description public.citext DEFAULT ''::public.citext
);


ALTER TABLE public.t_spectral_library_type OWNER TO d3l243;

--
-- Name: t_spectral_library_type_library_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_spectral_library_type ALTER COLUMN library_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_spectral_library_type_library_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_spectral_library_type pk_t_spectral_library_type; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_spectral_library_type
    ADD CONSTRAINT pk_t_spectral_library_type PRIMARY KEY (library_type_id);

ALTER TABLE public.t_spectral_library_type CLUSTER ON pk_t_spectral_library_type;

--
-- Name: ix_t_spectral_library_type_library_type; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_spectral_library_type_library_type ON public.t_spectral_library_type USING btree (library_type);

--
-- Name: TABLE t_spectral_library_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_spectral_library_type TO readaccess;
GRANT SELECT ON TABLE public.t_spectral_library_type TO writeaccess;

