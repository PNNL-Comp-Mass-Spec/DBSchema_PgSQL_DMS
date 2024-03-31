--
-- Name: v_enzymes_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_enzymes_list_report AS
 SELECT enzyme_id,
    enzyme_name,
    description,
    p1 AS left_cleave_residues,
    p1_exception AS left_exception,
    p2 AS right_cleave_residues,
    p2_exception AS right_exception,
    cleavage_method,
        CASE
            WHEN (cleavage_offset = 0) THEN 'Cleave Before'::public.citext
            ELSE 'Cleave After'::public.citext
        END AS cleavage_offset,
    protein_collection_name AS protein_collection,
    comment
   FROM public.t_enzymes;


ALTER VIEW public.v_enzymes_list_report OWNER TO d3l243;

--
-- Name: TABLE v_enzymes_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_enzymes_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_enzymes_list_report TO writeaccess;

