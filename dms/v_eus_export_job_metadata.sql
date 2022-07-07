--
-- Name: v_eus_export_job_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_job_metadata AS
 SELECT d.dataset_id,
    d.dataset,
    inst.instrument,
    dtn.dataset_type,
    dsn.dataset_state,
    drn.dataset_rating,
    e.experiment,
    o.organism,
    j.job AS analysis_job,
    antool.analysis_tool,
    antool.result_type AS analysis_result_type,
    j.protein_collection_list,
    j.results_folder_name AS analysis_job_results_folder,
    public.combine_paths((v_dataset_folder_paths.archive_folder_path)::text, (j.results_folder_name)::text) AS folder_path_aurora
   FROM (((((((((public.t_dataset d
     JOIN public.t_instrument_name inst ON ((d.instrument_id = inst.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((d.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_dataset_state_name dsn ON ((d.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_dataset_rating_name drn ON ((d.dataset_rating_id = drn.dataset_rating_id)))
     JOIN public.t_experiments e ON ((d.exp_id = e.exp_id)))
     JOIN public.t_organisms o ON ((e.organism_id = o.organism_id)))
     JOIN public.t_analysis_job j ON ((d.dataset_id = j.dataset_id)))
     JOIN public.t_analysis_tool antool ON ((j.analysis_tool_id = antool.analysis_tool_id)))
     JOIN public.v_dataset_folder_paths ON ((d.dataset_id = v_dataset_folder_paths.dataset_id)))
  WHERE (j.job_state_id = 4);


ALTER TABLE public.v_eus_export_job_metadata OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_job_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_job_metadata TO readaccess;

