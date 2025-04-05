--
-- Name: t_naming_authorities; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_naming_authorities (
    authority_id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    web_address public.citext
);


ALTER TABLE pc.t_naming_authorities OWNER TO d3l243;

--
-- Name: t_naming_authorities_authority_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_naming_authorities ALTER COLUMN authority_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_naming_authorities_authority_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_naming_authorities pk_t_naming_authorities; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_naming_authorities
    ADD CONSTRAINT pk_t_naming_authorities PRIMARY KEY (authority_id);

ALTER TABLE pc.t_naming_authorities CLUSTER ON pk_t_naming_authorities;

--
-- Name: TABLE t_naming_authorities; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_naming_authorities TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_naming_authorities TO writeaccess;

