--
-- Name: v_param_file_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_entry AS
 SELECT pf.param_file_id,
    pf.param_file_name,
    pft.param_file_type,
    pf.param_file_description,
    pf.valid,
    (((((('# Paste the static and dynamic mods here from a MSGF+ or MSPathFinder parameter file'::text || chr(10)) || '# Typically used when creating new parameter files'::text) || chr(10)) || '# Can also be used with existing parameter files if mass mods are not yet defined'::text) || chr(10)) || '# Alternatively, enable "Replace Existing Mass Mods"'::text) AS mass_mods
   FROM (public.t_param_files pf
     JOIN public.t_param_file_types pft ON ((pf.param_file_type_id = pft.param_file_type_id)));


ALTER TABLE public.v_param_file_entry OWNER TO d3l243;

--
-- Name: TABLE v_param_file_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_entry TO readaccess;

