--
-- Name: t_encrypted_collection_authorizations; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_encrypted_collection_authorizations (
    authorization_id integer NOT NULL,
    login_name public.citext NOT NULL,
    protein_collection_id integer CONSTRAINT t_encrypted_collection_authoriza_protein_collection_id_not_null NOT NULL
);


ALTER TABLE pc.t_encrypted_collection_authorizations OWNER TO d3l243;

--
-- Name: t_encrypted_collection_authorizations_authorization_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_encrypted_collection_authorizations ALTER COLUMN authorization_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_encrypted_collection_authorizations_authorization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_encrypted_collection_authorizations pk_t_encrypted_collection_authorizations; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_encrypted_collection_authorizations
    ADD CONSTRAINT pk_t_encrypted_collection_authorizations PRIMARY KEY (authorization_id);

ALTER TABLE pc.t_encrypted_collection_authorizations CLUSTER ON pk_t_encrypted_collection_authorizations;

--
-- Name: TABLE t_encrypted_collection_authorizations; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_encrypted_collection_authorizations TO readaccess;
GRANT SELECT ON TABLE pc.t_encrypted_collection_authorizations TO writeaccess;
GRANT INSERT,DELETE,UPDATE ON TABLE pc.t_encrypted_collection_authorizations TO pceditor;

