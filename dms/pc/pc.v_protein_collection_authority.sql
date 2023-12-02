--
-- Name: v_protein_collection_authority; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collection_authority AS
 SELECT pcm.protein_collection_id,
    pn.annotation_type_id
   FROM (pc.t_protein_collection_members pcm
     JOIN pc.t_protein_names pn ON ((pcm.protein_id = pn.protein_id)))
  GROUP BY pcm.protein_collection_id, pn.annotation_type_id;


ALTER VIEW pc.v_protein_collection_authority OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_authority; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collection_authority TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collection_authority TO writeaccess;

