--
-- Name: v_predefined_analysis_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_list_report AS
 SELECT pa.predefine_id AS id,
    pa.instrument_class_criteria AS instrument_class,
    pa.predefine_level AS level,
    pa.predefine_sequence AS seq,
    pa.next_level AS next_lvl,
    pa.enabled,
    pa.analysis_tool_name AS analysis_tool,
        CASE
            WHEN (pa.trigger_before_disposition = 1) THEN 'Before Disposition'::text
            ELSE 'Normal'::text
        END AS trigger_mode,
        CASE pa.propagation_mode
            WHEN 0 THEN 'Export'::text
            ELSE 'No Export'::text
        END AS export_mode,
    pa.instrument_name_criteria AS instrument_crit,
    pa.instrument_excl_criteria AS instrument_excl,
    pa.organism_name_criteria AS organism_crit,
    pa.campaign_name_criteria AS campaign_crit,
    pa.experiment_name_criteria AS experiment_crit,
    pa.labelling_incl_criteria AS exp_labeling_crit,
    pa.labelling_excl_criteria AS exp_labeling_excl,
    pa.dataset_name_criteria AS dataset_crit,
    pa.exp_comment_criteria AS exp_comment_crit,
    pa.separation_type_criteria AS separation_crit,
    pa.campaign_excl_criteria AS campaign_excl_crit,
    pa.experiment_excl_criteria AS experiment_excl_crit,
    pa.dataset_excl_criteria AS dataset_excl_crit,
    pa.dataset_type_criteria AS dataset_type_crit,
    pa.scan_count_min_criteria AS scan_count_min,
    pa.scan_count_max_criteria AS scan_count_max,
    pa.param_file_name AS param_file,
    pa.settings_file_name AS settings_file,
    org.organism,
    pa.organism_db_name AS organism_db,
    pa.protein_collection_list AS prot_coll_list,
    pa.protein_options_list AS prot_opts_list,
    pa.special_processing AS special_proc,
    pa.description,
    pa.priority,
    pa.last_affected
   FROM (public.t_predefined_analysis pa
     JOIN public.t_organisms org ON ((pa.organism_id = org.organism_id)));


ALTER TABLE public.v_predefined_analysis_list_report OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_predefined_analysis_list_report TO writeaccess;

