--
-- Name: t_spectral_library_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_spectral_library_state (
    library_state_id integer NOT NULL,
    library_state public.citext NOT NULL
);


ALTER TABLE public.t_spectral_library_state OWNER TO d3l243;

--
-- Name: t_spectral_library_state_library_state_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_spectral_library_state ALTER COLUMN library_state_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_spectral_library_state_library_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_spectral_library_state pk_t_spectral_library_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_spectral_library_state
    ADD CONSTRAINT pk_t_spectral_library_state PRIMARY KEY (library_state_id);

--
-- Name: ix_t_spectral_library_state_library_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_spectral_library_state_library_state ON public.t_spectral_library_state USING btree (library_state);

--
-- Name: TABLE t_spectral_library_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_spectral_library_state TO readaccess;
GRANT SELECT ON TABLE public.t_spectral_library_state TO writeaccess;

