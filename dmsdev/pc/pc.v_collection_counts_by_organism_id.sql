--
-- Name: v_collection_counts_by_organism_id; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_collection_counts_by_organism_id AS
 SELECT organism_id,
    count(protein_collection_id) AS collection_count
   FROM pc.t_collection_organism_xref orgxref
  GROUP BY organism_id;


ALTER VIEW pc.v_collection_counts_by_organism_id OWNER TO d3l243;

--
-- Name: TABLE v_collection_counts_by_organism_id; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_collection_counts_by_organism_id TO readaccess;
GRANT SELECT ON TABLE pc.v_collection_counts_by_organism_id TO writeaccess;

