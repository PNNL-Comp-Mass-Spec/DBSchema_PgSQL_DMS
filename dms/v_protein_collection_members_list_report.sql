--
-- Name: v_protein_collection_members_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_protein_collection_members_list_report AS
 SELECT pcm.protein_collection_id,
    pc.collection_name AS protein_collection,
    pcm.protein_name,
    pcm.description,
    pcm.reference_id,
    pcm.residue_count,
    pcm.monoisotopic_mass,
    pcm.protein_id
   FROM (pc.t_protein_collection_members_cached pcm
     JOIN pc.t_protein_collections pc ON ((pcm.protein_collection_id = pc.protein_collection_id)));


ALTER TABLE public.v_protein_collection_members_list_report OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_members_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_protein_collection_members_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_protein_collection_members_list_report TO writeaccess;

