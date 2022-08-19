--
-- Name: t_encrypted_collection_passphrases; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_encrypted_collection_passphrases (
    passphrase_id integer NOT NULL,
    passphrase public.citext NOT NULL,
    protein_collection_id integer NOT NULL
);


ALTER TABLE pc.t_encrypted_collection_passphrases OWNER TO d3l243;

--
-- Name: t_encrypted_collection_passphrases_passphrase_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_encrypted_collection_passphrases ALTER COLUMN passphrase_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_encrypted_collection_passphrases_passphrase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_encrypted_collection_passphrases pk_t_encrypted_collection_passphrases; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_encrypted_collection_passphrases
    ADD CONSTRAINT pk_t_encrypted_collection_passphrases PRIMARY KEY (passphrase_id);

--
-- Name: TABLE t_encrypted_collection_passphrases; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_encrypted_collection_passphrases TO readaccess;

