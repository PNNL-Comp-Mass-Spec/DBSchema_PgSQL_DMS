--
-- Name: v_pde_filter_sets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_pde_filter_sets AS
 SELECT filter_set_id,
    filter_set_name AS name,
    filter_set_description AS description
   FROM public.t_filter_sets;


ALTER VIEW public.v_pde_filter_sets OWNER TO d3l243;

--
-- Name: VIEW v_pde_filter_sets; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_pde_filter_sets IS 'Originally used by PRISM Data Extractor, then StarSuite Extractor, both of which were retired in 2011 when Mage Extractor was released. Referenced by results filter code in Mage, but the code and GUI controls were deprecated in 2024.';

--
-- Name: TABLE v_pde_filter_sets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_pde_filter_sets TO readaccess;
GRANT SELECT ON TABLE public.v_pde_filter_sets TO writeaccess;

