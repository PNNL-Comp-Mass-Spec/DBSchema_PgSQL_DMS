--
-- Name: v_enzyme_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_enzyme_export AS
 SELECT enzyme_id,
    enzyme_name,
    description,
    p1,
    p1_exception,
    p2,
    p2_exception,
    cleavage_method,
    cleavage_offset,
    sequest_enzyme_index,
    protein_collection_name
   FROM public.t_enzymes;


ALTER VIEW public.v_enzyme_export OWNER TO d3l243;

--
-- Name: TABLE v_enzyme_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_enzyme_export TO readaccess;
GRANT SELECT ON TABLE public.v_enzyme_export TO writeaccess;

