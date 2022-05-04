--
-- Name: t_internal_standards; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_standards (
    internal_standard_id integer NOT NULL,
    parent_mix_id integer,
    name public.citext NOT NULL,
    description public.citext,
    type public.citext,
    active character(1) DEFAULT 'A'::bpchar NOT NULL
);


ALTER TABLE public.t_internal_standards OWNER TO d3l243;

--
-- Name: t_internal_standards_internal_standard_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_internal_standards ALTER COLUMN internal_standard_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_internal_standards_internal_standard_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_internal_standards pk_t_internal_standards; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_internal_standards
    ADD CONSTRAINT pk_t_internal_standards PRIMARY KEY (internal_standard_id);

--
-- Name: ix_t_internal_standards; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_internal_standards ON public.t_internal_standards USING btree (name);

--
-- Name: TABLE t_internal_standards; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_standards TO readaccess;

