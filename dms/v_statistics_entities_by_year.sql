--
-- Name: v_statistics_entities_by_year; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_statistics_entities_by_year AS
 SELECT pivotdata.year,
    COALESCE(pivotdata.new_research_campaigns, 0) AS new_research_campaigns,
    COALESCE(pivotdata.new_organisms, 0) AS new_organisms,
    COALESCE(pivotdata.prepared_samples, 0) AS prepared_samples,
    COALESCE(pivotdata.requested_instrument_runs, 0) AS requested_instrument_runs,
    COALESCE(pivotdata.datasets, 0) AS datasets,
    COALESCE(pivotdata.analysis_jobs, 0) AS analysis_jobs,
    COALESCE(pivotdata.data_packages, 0) AS data_packages,
    COALESCE(pivotdata.analysis_job_step_tool_started, 0) AS analysis_job_step_tool_started,
    COALESCE(pivotdata.capture_task_step_tool_started, 0) AS capture_task_step_tool_started
   FROM public.crosstab('SELECT extract(year from Start) AS Year,
             ''analysis_jobs'' AS Item,
             COUNT(*) AS Items
      FROM public.t_analysis_job INNER JOIN
           public.t_analysis_tool
             ON public.t_analysis_job.analysis_tool_id = public.t_analysis_tool.analysis_tool_id
      WHERE NOT start IS NULL AND
            public.t_analysis_tool.analysis_tool <> ''MSClusterDAT_Gen''
      GROUP BY extract(year from Start)
      UNION
      SELECT extract(year from Created) AS Year,
             ''datasets'' AS Item,
             COUNT(*) AS Items
      FROM public.t_dataset
      WHERE dataset_type_ID <> 100   -- Exclude tracking datasets
      GROUP BY extract(year from Created)
      UNION
      SELECT extract(year from Created) AS Year,
             ''prepared_samples'' AS Item,
             COUNT(*) AS Items
      FROM public.t_experiments
      GROUP BY extract(year from Created)
      UNION
      SELECT extract(year from Created) AS Year,
             ''requested_instrument_runs'' AS Item,
             COUNT(*) AS Items
      FROM public.t_requested_run
      GROUP BY extract(year from Created)
      UNION
      SELECT extract(year from Created) AS Year,
             ''new_organisms'' AS Item,
             COUNT(*) AS Items
      FROM public.t_organisms
      GROUP BY extract(year from Created)
      UNION
      SELECT extract(year from Created) AS Year,
             ''new_research_campaigns'' AS Item,
             COUNT(*) AS Items
      FROM public.t_campaign
      GROUP BY extract(year from Created)
      UNION
      SELECT extract(year from Created) AS Year,
             ''data_packages'' AS Item,
             COUNT(*) AS Items
      FROM dpkg.T_Data_Package
      GROUP BY extract(year from Created)
      UNION
      SELECT extract(year from Start) AS Year,
             ''analysis_job_step_tool_started'' AS Item,
             COUNT(*) AS Items
      FROM sw.T_Job_Steps_History
      WHERE NOT Start IS NULL
      GROUP BY extract(year from Start)
      UNION
      SELECT extract(year from Start) AS Year,
             ''capture_task_step_tool_started'' AS Item,
             COUNT(*) AS Items
      FROM cap.T_Task_Steps_History
      WHERE NOT Start IS NULL
      GROUP BY extract(year from Start)
      ORDER BY Year, Item'::text, 'SELECT unnest(''{new_research_campaigns, new_organisms, prepared_samples,
                     requested_instrument_runs, datasets, analysis_jobs, data_packages,
                     analysis_job_step_tool_started, capture_task_step_tool_started}''::text[])'::text) pivotdata(year integer, new_research_campaigns integer, new_organisms integer, prepared_samples integer, requested_instrument_runs integer, datasets integer, analysis_jobs integer, data_packages integer, analysis_job_step_tool_started integer, capture_task_step_tool_started integer);


ALTER TABLE public.v_statistics_entities_by_year OWNER TO d3l243;

--
-- Name: VIEW v_statistics_entities_by_year; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_statistics_entities_by_year IS 'Dataset stats exclude tracking datasets (which have dataset_type_ID = 100)';

--
-- Name: TABLE v_statistics_entities_by_year; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_statistics_entities_by_year TO readaccess;

