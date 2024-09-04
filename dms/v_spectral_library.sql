--
-- Name: v_spectral_library; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_spectral_library AS
 SELECT sl.library_id,
    sl.library_name,
    sl.library_state_id,
    libstate.library_state,
    sl.last_affected,
    sl.library_type_id,
    libtype.library_type,
    sl.created,
    sl.source_job,
    sl.comment,
    sl.storage_path,
    sl.protein_collection_list,
    sl.organism_db_file,
    sl.fragment_ion_mz_min,
    sl.fragment_ion_mz_max,
    sl.trim_n_terminal_met,
    sl.cleavage_specificity,
    sl.missed_cleavages,
    sl.peptide_length_min,
    sl.peptide_length_max,
    sl.precursor_mz_min,
    sl.precursor_mz_max,
    sl.precursor_charge_min,
    sl.precursor_charge_max,
    sl.static_cys_carbamidomethyl,
    sl.static_mods,
    sl.dynamic_mods,
    sl.max_dynamic_mods,
    sl.program_version,
    sl.settings_hash,
    sl.completion_code
   FROM ((public.t_spectral_library sl
     JOIN public.t_spectral_library_state libstate ON ((sl.library_state_id = libstate.library_state_id)))
     JOIN public.t_spectral_library_type libtype ON ((sl.library_type_id = libtype.library_type_id)));


ALTER VIEW public.v_spectral_library OWNER TO d3l243;

--
-- Name: v_spectral_library trig_v_spectral_library_instead_of_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_v_spectral_library_instead_of_update INSTEAD OF UPDATE ON public.v_spectral_library FOR EACH ROW EXECUTE FUNCTION public.trigfn_v_spectral_library_instead_of_update();

--
-- Name: TABLE v_spectral_library; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_spectral_library TO readaccess;
GRANT SELECT ON TABLE public.v_spectral_library TO writeaccess;

