--
-- Name: t_lc_column; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_column (
    lc_column_id integer NOT NULL,
    lc_column public.citext NOT NULL,
    packing_mfg public.citext DEFAULT 'na'::public.citext NOT NULL,
    packing_type public.citext NOT NULL,
    particle_size public.citext NOT NULL,
    particle_type public.citext NOT NULL,
    column_inner_dia public.citext NOT NULL,
    column_outer_dia public.citext NOT NULL,
    column_length public.citext NOT NULL,
    column_state_id integer DEFAULT 0 NOT NULL,
    operator_username public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_lc_column OWNER TO d3l243;

--
-- Name: t_lc_column_lc_column_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_lc_column ALTER COLUMN lc_column_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_lc_column_lc_column_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_lc_column pk_t_lc_column; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_column
    ADD CONSTRAINT pk_t_lc_column PRIMARY KEY (lc_column_id);

--
-- Name: ix_t_lc_column; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_lc_column ON public.t_lc_column USING btree (lc_column);

--
-- Name: ix_t_lc_column_id_include_sccolumn_number; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_lc_column_id_include_sccolumn_number ON public.t_lc_column USING btree (lc_column_id) INCLUDE (lc_column, column_state_id);

--
-- Name: t_lc_column fk_t_lc_column_t_lc_column_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_column
    ADD CONSTRAINT fk_t_lc_column_t_lc_column_state_name FOREIGN KEY (column_state_id) REFERENCES public.t_lc_column_state_name(column_state_id);

--
-- Name: t_lc_column fk_t_lc_column_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_column
    ADD CONSTRAINT fk_t_lc_column_t_users FOREIGN KEY (operator_username) REFERENCES public.t_users(username);

--
-- Name: TABLE t_lc_column; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_column TO readaccess;
GRANT SELECT ON TABLE public.t_lc_column TO writeaccess;

