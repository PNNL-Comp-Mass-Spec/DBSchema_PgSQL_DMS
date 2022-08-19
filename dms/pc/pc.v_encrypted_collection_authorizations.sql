--
-- Name: v_encrypted_collection_authorizations; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_encrypted_collection_authorizations AS
 SELECT eca.login_name,
    eca.protein_collection_id,
        CASE
            WHEN (eca.protein_collection_id = 0) THEN 'Administrator'::public.citext
            ELSE pc.collection_name
        END AS protein_collection_name
   FROM (pc.t_encrypted_collection_authorizations eca
     LEFT JOIN pc.t_protein_collections pc ON ((eca.protein_collection_id = pc.protein_collection_id)));


ALTER TABLE pc.v_encrypted_collection_authorizations OWNER TO d3l243;

--
-- Name: TABLE v_encrypted_collection_authorizations; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_encrypted_collection_authorizations TO readaccess;
GRANT SELECT ON TABLE pc.v_encrypted_collection_authorizations TO writeaccess;

