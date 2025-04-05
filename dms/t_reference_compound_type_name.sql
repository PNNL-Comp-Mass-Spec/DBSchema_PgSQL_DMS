--
-- Name: t_reference_compound_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_reference_compound_type_name (
    compound_type_id integer NOT NULL,
    compound_type_name public.citext NOT NULL
);


ALTER TABLE public.t_reference_compound_type_name OWNER TO d3l243;

--
-- Name: t_reference_compound_type_name_compound_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_reference_compound_type_name ALTER COLUMN compound_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_reference_compound_type_name_compound_type_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_reference_compound_type_name pk_t_reference_compound_type_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reference_compound_type_name
    ADD CONSTRAINT pk_t_reference_compound_type_name PRIMARY KEY (compound_type_id);

ALTER TABLE public.t_reference_compound_type_name CLUSTER ON pk_t_reference_compound_type_name;

--
-- Name: ix_t_reference_compound_type_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_reference_compound_type_name ON public.t_reference_compound_type_name USING btree (compound_type_name);

--
-- Name: TABLE t_reference_compound_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_reference_compound_type_name TO readaccess;
GRANT SELECT ON TABLE public.t_reference_compound_type_name TO writeaccess;

