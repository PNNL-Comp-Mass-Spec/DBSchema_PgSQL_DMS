--
-- Name: v_enzyme_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_enzyme_export AS
 SELECT t_enzymes.enzyme_id,
    t_enzymes.enzyme_name,
    t_enzymes.description,
    t_enzymes.p1,
    t_enzymes.p1_exception,
    t_enzymes.p2,
    t_enzymes.p2_exception,
    t_enzymes.cleavage_method,
    t_enzymes.cleavage_offset,
    t_enzymes.sequest_enzyme_index,
    t_enzymes.protein_collection_name
   FROM public.t_enzymes;


ALTER VIEW public.v_enzyme_export OWNER TO d3l243;

--
-- Name: TABLE v_enzyme_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_enzyme_export TO readaccess;
GRANT SELECT ON TABLE public.v_enzyme_export TO writeaccess;

