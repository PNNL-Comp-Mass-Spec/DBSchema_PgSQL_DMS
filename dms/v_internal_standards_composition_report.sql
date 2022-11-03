--
-- Name: v_internal_standards_composition_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_internal_standards_composition_report AS
 SELECT components.name AS component,
    components.description AS component_description,
    composition.concentration,
    components.monoisotopic_mass,
    components.charge_minimum,
    components.charge_maximum,
    components.charge_highest_abu,
    components.expected_ganet,
    components.internal_std_component_id AS id,
    istds.name
   FROM ((public.t_internal_std_parent_mixes parentmix
     JOIN public.t_internal_standards istds ON ((parentmix.parent_mix_id = istds.parent_mix_id)))
     JOIN (public.t_internal_std_components components
     JOIN public.t_internal_std_composition composition ON ((components.internal_std_component_id = composition.component_id))) ON ((parentmix.parent_mix_id = composition.mix_id)));


ALTER TABLE public.v_internal_standards_composition_report OWNER TO d3l243;

--
-- Name: TABLE v_internal_standards_composition_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_internal_standards_composition_report TO readaccess;
GRANT SELECT ON TABLE public.v_internal_standards_composition_report TO writeaccess;

