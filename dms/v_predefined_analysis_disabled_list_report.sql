--
-- Name: v_predefined_analysis_disabled_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_disabled_list_report AS
 SELECT pa.predefine_id AS id,
    pa.instrument_class_criteria AS instrument_class,
    pa.predefine_level AS level,
    pa.predefine_sequence AS seq,
    pa.next_level AS next_lvl,
    pa.analysis_tool_name AS analysis_tool,
        CASE
            WHEN (pa.trigger_before_disposition = 1) THEN 'Before Disposition'::public.citext
            ELSE 'Normal'::public.citext
        END AS trigger_mode,
        CASE pa.propagation_mode
            WHEN 0 THEN 'Export'::public.citext
            ELSE 'No Export'::public.citext
        END AS export_mode,
    pa.instrument_name_criteria AS instrument_crit,
    pa.instrument_excl_criteria AS instrument_excl,
    pa.organism_name_criteria AS organism_crit,
    pa.campaign_name_criteria AS campaign_crit,
    pa.campaign_excl_criteria AS campaign_excl,
    pa.experiment_name_criteria AS experiment_crit,
    pa.experiment_excl_criteria AS experiment_excl,
    pa.exp_comment_criteria AS exp_comment_crit,
    pa.dataset_name_criteria AS dataset_crit,
    pa.dataset_excl_criteria AS dataset_excl,
    pa.dataset_type_criteria AS dataset_type_crit,
    pa.scan_type_criteria AS scan_type_crit,
    pa.scan_type_excl_criteria AS scan_type_excl,
    pa.labelling_incl_criteria AS exp_labeling_crit,
    pa.labelling_excl_criteria AS exp_labeling_excl,
    pa.separation_type_criteria AS separation_crit,
    pa.param_file_name AS param_file,
    pa.settings_file_name AS settings_file,
    org.organism,
    pa.organism_db_name AS organism_db,
    pa.protein_collection_list AS prot_coll_list,
    pa.protein_options_list AS prot_opts_list,
    pa.priority,
    pa.description,
    pa.special_processing AS special_proc,
    pa.created,
    pa.last_affected
   FROM (public.t_predefined_analysis pa
     JOIN public.t_organisms org ON ((pa.organism_id = org.organism_id)))
  WHERE (pa.enabled = 0);


ALTER VIEW public.v_predefined_analysis_disabled_list_report OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_disabled_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_disabled_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_predefined_analysis_disabled_list_report TO writeaccess;

