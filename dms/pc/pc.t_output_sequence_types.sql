--
-- Name: t_output_sequence_types; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_output_sequence_types (
    output_sequence_type_id integer NOT NULL,
    output_sequence_type public.citext,
    display public.citext,
    description public.citext
);


ALTER TABLE pc.t_output_sequence_types OWNER TO d3l243;

--
-- Name: t_output_sequence_types_output_sequence_type_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_output_sequence_types ALTER COLUMN output_sequence_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_output_sequence_types_output_sequence_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_output_sequence_types pk_t_output_sequence_types; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_output_sequence_types
    ADD CONSTRAINT pk_t_output_sequence_types PRIMARY KEY (output_sequence_type_id);

--
-- Name: TABLE t_output_sequence_types; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_output_sequence_types TO readaccess;
GRANT SELECT ON TABLE pc.t_output_sequence_types TO writeaccess;

