--
-- Name: t_factor; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_factor (
    factor_id integer NOT NULL,
    type public.citext DEFAULT 'Run_Request'::public.citext NOT NULL,
    target_id integer NOT NULL,
    name public.citext NOT NULL,
    value public.citext NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_factor OWNER TO d3l243;

--
-- Name: t_factor_factor_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_factor ALTER COLUMN factor_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_factor_factor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_factor pk_t_factor; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_factor
    ADD CONSTRAINT pk_t_factor PRIMARY KEY (factor_id);

--
-- Name: ix_t_factor_type_target_id_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_factor_type_target_id_name ON public.t_factor USING btree (type, target_id, name);

--
-- Name: TABLE t_factor; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_factor TO readaccess;
GRANT SELECT ON TABLE public.t_factor TO writeaccess;

