--
-- Name: t_emsl_instrument_usage_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_emsl_instrument_usage_type (
    usage_type_id smallint NOT NULL,
    usage_type public.citext NOT NULL,
    description public.citext,
    enabled smallint NOT NULL
);


ALTER TABLE public.t_emsl_instrument_usage_type OWNER TO d3l243;

--
-- Name: t_emsl_instrument_usage_type_usage_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_emsl_instrument_usage_type ALTER COLUMN usage_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_emsl_instrument_usage_type_usage_type_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_emsl_instrument_usage_type pk_t_emsl_instrument_usage_type; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instrument_usage_type
    ADD CONSTRAINT pk_t_emsl_instrument_usage_type PRIMARY KEY (usage_type_id);

--
-- Name: TABLE t_emsl_instrument_usage_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instrument_usage_type TO readaccess;

