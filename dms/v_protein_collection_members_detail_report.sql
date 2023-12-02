--
-- Name: v_protein_collection_members_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_protein_collection_members_detail_report AS
 SELECT 'Use V_Protein_Collection_Members_List_Report or use stored procedure GetProteinCollectionMemberDetail'::text AS message,
    'When using pc.V_Protein_Collection_Members, always use as where clause'::text AS warning;


ALTER VIEW public.v_protein_collection_members_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_members_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_protein_collection_members_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_protein_collection_members_detail_report TO writeaccess;

