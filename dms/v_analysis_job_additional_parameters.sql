--
-- Name: v_analysis_job_additional_parameters; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_additional_parameters AS
 SELECT j.job,
    instclass.instrument_class,
    instclass.raw_data_type,
    tool.search_engine_input_file_formats,
    org.organism AS organism_name,
    tool.org_db_required AS org_db_reqd,
    j.protein_collection_list,
    j.protein_options_list
   FROM (((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)));


ALTER TABLE public.v_analysis_job_additional_parameters OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_additional_parameters; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_additional_parameters TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_additional_parameters TO writeaccess;

