--
-- Name: v_internal_standards_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_internal_standards_export AS
 SELECT istds.name,
    istds.description,
    parentmix.name AS mix_name,
    components.name AS component,
    components.description AS component_description,
    composition.concentration,
    components.monoisotopic_mass,
    components.charge_minimum,
    components.charge_maximum,
    components.charge_highest_abu,
    components.expected_ganet,
    components.internal_std_component_id,
    istds.internal_standard_id AS internal_std_mix_id
   FROM ((public.t_internal_std_parent_mixes parentmix
     JOIN public.t_internal_standards istds ON ((parentmix.parent_mix_id = istds.parent_mix_id)))
     JOIN (public.t_internal_std_components components
     JOIN public.t_internal_std_composition composition ON ((components.internal_std_component_id = composition.component_id))) ON ((parentmix.parent_mix_id = composition.mix_id)));


ALTER TABLE public.v_internal_standards_export OWNER TO d3l243;

--
-- Name: TABLE v_internal_standards_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_internal_standards_export TO readaccess;
GRANT SELECT ON TABLE public.v_internal_standards_export TO writeaccess;

