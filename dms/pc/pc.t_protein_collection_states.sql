--
-- Name: t_protein_collection_states; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_protein_collection_states (
    collection_state_id smallint NOT NULL,
    state public.citext NOT NULL,
    description public.citext NOT NULL
);


ALTER TABLE pc.t_protein_collection_states OWNER TO d3l243;

--
-- Name: t_protein_collection_states pk_t_protein_collection_states; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_states
    ADD CONSTRAINT pk_t_protein_collection_states PRIMARY KEY (collection_state_id);

ALTER TABLE pc.t_protein_collection_states CLUSTER ON pk_t_protein_collection_states;

--
-- Name: TABLE t_protein_collection_states; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_protein_collection_states TO readaccess;
GRANT SELECT ON TABLE pc.t_protein_collection_states TO writeaccess;

