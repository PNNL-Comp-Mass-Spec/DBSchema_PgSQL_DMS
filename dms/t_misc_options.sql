--
-- Name: t_misc_options; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_misc_options (
    name public.citext NOT NULL,
    id integer NOT NULL,
    value public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_misc_options OWNER TO d3l243;

--
-- Name: t_misc_options_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_misc_options ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_misc_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_misc_options pk_t_misc_options; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_misc_options
    ADD CONSTRAINT pk_t_misc_options PRIMARY KEY (name);

--
-- Name: ix_t_misc_options_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_misc_options_id ON public.t_misc_options USING btree (id);

--
-- Name: TABLE t_misc_options; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_misc_options TO readaccess;

