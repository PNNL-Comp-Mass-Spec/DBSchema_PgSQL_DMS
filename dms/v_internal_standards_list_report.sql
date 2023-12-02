--
-- Name: v_internal_standards_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_internal_standards_list_report AS
 SELECT istds.name,
    istds.internal_standard_id AS id,
    istds.description,
    count(composition.component_id) AS components,
    istds.type,
    COALESCE(parentmix.name, ''::public.citext) AS mix_name,
    COALESCE(parentmix.protein_collection_name, ''::public.citext) AS protein_collection_name,
    istds.active
   FROM ((public.t_internal_std_composition composition
     RIGHT JOIN public.t_internal_std_parent_mixes parentmix ON ((composition.mix_id = parentmix.parent_mix_id)))
     RIGHT JOIN public.t_internal_standards istds ON ((parentmix.parent_mix_id = istds.parent_mix_id)))
  GROUP BY istds.name, istds.description, istds.type, istds.active, istds.internal_standard_id, parentmix.name, parentmix.protein_collection_name;


ALTER VIEW public.v_internal_standards_list_report OWNER TO d3l243;

--
-- Name: TABLE v_internal_standards_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_internal_standards_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_internal_standards_list_report TO writeaccess;

