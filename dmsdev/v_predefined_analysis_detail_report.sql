--
-- Name: v_predefined_analysis_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_detail_report AS
 SELECT pa.predefine_id AS id,
    pa.instrument_class_criteria,
    pa.predefine_level AS level,
    pa.predefine_sequence AS sequence,
    pa.next_level,
        CASE
            WHEN (pa.trigger_before_disposition = 1) THEN 'Before Disposition'::public.citext
            ELSE 'Normal'::public.citext
        END AS trigger_mode,
        CASE pa.propagation_mode
            WHEN 0 THEN 'Export'::public.citext
            ELSE 'No Export'::public.citext
        END AS export_mode,
    pa.instrument_name_criteria AS instrument_criteria,
    pa.instrument_excl_criteria AS instrument_exclusion,
    pa.organism_name_criteria AS organism_criteria,
    pa.campaign_name_criteria AS campaign_criteria,
    pa.campaign_excl_criteria AS campaign_exclusion,
    pa.experiment_name_criteria AS experiment_criteria,
    pa.experiment_excl_criteria AS experiment_exclusion,
    pa.exp_comment_criteria AS experiment_comment_criteria,
    pa.dataset_name_criteria AS dataset_criteria,
    pa.dataset_excl_criteria AS dataset_exclusion,
    pa.dataset_type_criteria,
    pa.scan_type_criteria,
    pa.scan_type_excl_criteria AS scan_type_exclusion,
    pa.labelling_incl_criteria AS experiment_labelling_criteria,
    pa.labelling_excl_criteria AS experiment_labelling_exclusion,
    pa.separation_type_criteria AS separation_criteria,
    pa.scan_count_min_criteria,
    pa.scan_count_max_criteria,
    pa.analysis_tool_name,
    pa.param_file_name,
    pa.settings_file_name,
    org.organism AS organism_name,
    pa.organism_db_name,
    pa.protein_collection_list,
    pa.protein_options_list,
    pa.priority,
    pa.enabled,
    pa.description,
    pa.special_processing,
    pa.created,
    pa.creator,
    pa.last_affected
   FROM (public.t_predefined_analysis pa
     JOIN public.t_organisms org ON ((pa.organism_id = org.organism_id)));


ALTER VIEW public.v_predefined_analysis_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_predefined_analysis_detail_report TO writeaccess;

