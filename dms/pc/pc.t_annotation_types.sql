--
-- Name: t_annotation_types; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_annotation_types (
    annotation_type_id integer NOT NULL,
    type_name public.citext NOT NULL,
    description public.citext,
    example public.citext,
    authority_id integer NOT NULL
);


ALTER TABLE pc.t_annotation_types OWNER TO d3l243;

--
-- Name: t_annotation_types_annotation_type_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_annotation_types ALTER COLUMN annotation_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_annotation_types_annotation_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_annotation_types pk_t_annotation_types; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_annotation_types
    ADD CONSTRAINT pk_t_annotation_types PRIMARY KEY (annotation_type_id);

--
-- Name: t_annotation_types fk_t_annotation_types_t_naming_authorities; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_annotation_types
    ADD CONSTRAINT fk_t_annotation_types_t_naming_authorities FOREIGN KEY (authority_id) REFERENCES pc.t_naming_authorities(authority_id);

--
-- Name: TABLE t_annotation_types; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_annotation_types TO readaccess;

