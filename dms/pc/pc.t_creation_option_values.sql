--
-- Name: t_creation_option_values; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_creation_option_values (
    value_id integer NOT NULL,
    value_string public.citext NOT NULL,
    display public.citext,
    description public.citext,
    keyword_id integer NOT NULL
);


ALTER TABLE pc.t_creation_option_values OWNER TO d3l243;

--
-- Name: t_creation_option_values_value_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_creation_option_values ALTER COLUMN value_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_creation_option_values_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_creation_option_values pk_t_creation_option_values; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_creation_option_values
    ADD CONSTRAINT pk_t_creation_option_values PRIMARY KEY (value_id);

--
-- Name: TABLE t_creation_option_values; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_creation_option_values TO readaccess;

