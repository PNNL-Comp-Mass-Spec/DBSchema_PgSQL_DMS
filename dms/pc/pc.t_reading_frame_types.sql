--
-- Name: t_reading_frame_types; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_reading_frame_types (
    reading_frame_type_id smallint NOT NULL,
    name public.citext,
    description public.citext
);


ALTER TABLE pc.t_reading_frame_types OWNER TO d3l243;

--
-- Name: t_reading_frame_types_reading_frame_type_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_reading_frame_types ALTER COLUMN reading_frame_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_reading_frame_types_reading_frame_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_reading_frame_types pk_t_reading_frame_types; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_reading_frame_types
    ADD CONSTRAINT pk_t_reading_frame_types PRIMARY KEY (reading_frame_type_id);

ALTER TABLE pc.t_reading_frame_types CLUSTER ON pk_t_reading_frame_types;

--
-- Name: TABLE t_reading_frame_types; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_reading_frame_types TO readaccess;
GRANT SELECT ON TABLE pc.t_reading_frame_types TO writeaccess;

