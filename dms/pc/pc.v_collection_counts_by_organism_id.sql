--
-- Name: v_collection_counts_by_organism_id; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_collection_counts_by_organism_id AS
 SELECT orgxref.organism_id,
    count(orgxref.protein_collection_id) AS collection_count
   FROM pc.t_collection_organism_xref orgxref
  GROUP BY orgxref.organism_id;


ALTER TABLE pc.v_collection_counts_by_organism_id OWNER TO d3l243;

