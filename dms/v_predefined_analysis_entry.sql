--
-- Name: v_predefined_analysis_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_entry AS
 SELECT pa.predefine_level AS level,
    pa.predefine_sequence AS sequence,
    pa.instrument_class_criteria,
    pa.campaign_name_criteria,
    pa.experiment_name_criteria,
    pa.instrument_name_criteria,
    pa.instrument_excl_criteria,
    pa.organism_name_criteria,
    pa.dataset_name_criteria,
    pa.exp_comment_criteria,
    pa.labelling_incl_criteria,
    pa.labelling_excl_criteria,
    pa.separation_type_criteria,
    pa.campaign_excl_criteria,
    pa.experiment_excl_criteria,
    pa.dataset_excl_criteria,
    pa.dataset_type_criteria,
    pa.analysis_tool_name,
    pa.param_file_name,
    pa.settings_file_name,
    org.organism AS organism_name,
    pa.organism_db_name,
    pa.protein_collection_list AS prot_coll_name_list,
    pa.protein_options_list AS prot_coll_options_list,
    pa.priority,
    pa.enabled,
    pa.created,
    pa.description,
    pa.creator,
    pa.predefine_id AS id,
    pa.next_level,
    pa.trigger_before_disposition,
        CASE pa.propagation_mode
            WHEN 0 THEN 'Export'::text
            ELSE 'No Export'::text
        END AS propagation_mode,
    pa.special_processing
   FROM (public.t_predefined_analysis pa
     JOIN public.t_organisms org ON ((pa.organism_id = org.organism_id)));


ALTER TABLE public.v_predefined_analysis_entry OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_entry TO readaccess;
GRANT SELECT ON TABLE public.v_predefined_analysis_entry TO writeaccess;

