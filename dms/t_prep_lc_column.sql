--
-- Name: t_prep_lc_column; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_prep_lc_column (
    prep_column_id integer NOT NULL,
    prep_column public.citext NOT NULL,
    mfg_name public.citext,
    mfg_model public.citext,
    mfg_serial public.citext,
    packing_mfg public.citext DEFAULT 'na'::public.citext NOT NULL,
    packing_type public.citext NOT NULL,
    particle_size public.citext NOT NULL,
    particle_type public.citext NOT NULL,
    column_inner_dia public.citext NOT NULL,
    column_outer_dia public.citext NOT NULL,
    length public.citext NOT NULL,
    state public.citext DEFAULT 'New'::public.citext NOT NULL,
    operator_username public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_t_prep_lc_column_prep_column_name_whitespace CHECK ((public.has_whitespace_chars((prep_column)::text, false) = false))
);


ALTER TABLE public.t_prep_lc_column OWNER TO d3l243;

--
-- Name: t_prep_lc_column_prep_column_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_prep_lc_column ALTER COLUMN prep_column_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_prep_lc_column_prep_column_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_prep_lc_column pk_t_prep_lc_column; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_column
    ADD CONSTRAINT pk_t_prep_lc_column PRIMARY KEY (prep_column_id);

--
-- Name: ix_t_prep_lc_column; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_prep_lc_column ON public.t_prep_lc_column USING btree (prep_column);

--
-- Name: TABLE t_prep_lc_column; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_lc_column TO readaccess;
GRANT SELECT ON TABLE public.t_prep_lc_column TO writeaccess;

