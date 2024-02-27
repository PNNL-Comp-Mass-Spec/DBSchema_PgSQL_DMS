--
-- Name: t_passphrase_hashes; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_passphrase_hashes (
    passphrase_hash_id integer NOT NULL,
    passphrase_sha1_hash public.citext NOT NULL,
    protein_collection_id integer NOT NULL,
    passphrase_id integer NOT NULL
);


ALTER TABLE pc.t_passphrase_hashes OWNER TO d3l243;

--
-- Name: t_passphrase_hashes_passphrase_hash_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_passphrase_hashes ALTER COLUMN passphrase_hash_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_passphrase_hashes_passphrase_hash_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_passphrase_hashes pk_t_passphrase_hashes; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_passphrase_hashes
    ADD CONSTRAINT pk_t_passphrase_hashes PRIMARY KEY (passphrase_hash_id);

--
-- Name: TABLE t_passphrase_hashes; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_passphrase_hashes TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_passphrase_hashes TO writeaccess;

