--
-- Name: v_reporter_ion_observation_rate_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_reporter_ion_observation_rate_list_report AS
 SELECT obsrate.job,
    obsrate.dataset_id,
    ds.dataset,
    obsrate.reporter_ion,
    ((((((dfp.dataset_url)::text || '/'::text) || (aj.results_folder_name)::text) || '/'::text) || (ds.dataset)::text) || '_RepIonObsRateHighAbundance.png'::text) AS observation_rate_link,
    ((((((dfp.dataset_url)::text || '/'::text) || (aj.results_folder_name)::text) || '/'::text) || (ds.dataset)::text) || '_RepIonStatsHighAbundance.png'::text) AS intensity_stats_link,
    inst.instrument,
    obsrate.channel1,
    obsrate.channel2,
    obsrate.channel3,
    obsrate.channel4,
    obsrate.channel5,
    obsrate.channel6,
    obsrate.channel7,
    obsrate.channel8,
    obsrate.channel9,
    obsrate.channel10,
    obsrate.channel11,
    obsrate.channel12,
    obsrate.channel13,
    obsrate.channel14,
    obsrate.channel15,
    obsrate.channel16,
    obsrate.channel1_median_intensity AS channel1_intensity,
    obsrate.channel2_median_intensity AS channel2_intensity,
    obsrate.channel3_median_intensity AS channel3_intensity,
    obsrate.channel4_median_intensity AS channel4_intensity,
    obsrate.channel5_median_intensity AS channel5_intensity,
    obsrate.channel6_median_intensity AS channel6_intensity,
    obsrate.channel7_median_intensity AS channel7_intensity,
    obsrate.channel8_median_intensity AS channel8_intensity,
    obsrate.channel9_median_intensity AS channel9_intensity,
    obsrate.channel10_median_intensity AS channel10_intensity,
    obsrate.channel11_median_intensity AS channel11_intensity,
    obsrate.channel12_median_intensity AS channel12_intensity,
    obsrate.channel13_median_intensity AS channel13_intensity,
    obsrate.channel14_median_intensity AS channel14_intensity,
    obsrate.channel15_median_intensity AS channel15_intensity,
    obsrate.channel16_median_intensity AS channel16_intensity,
    aj.param_file_name AS param_file,
    obsrate.entered
   FROM ((((public.t_reporter_ion_observation_rates obsrate
     JOIN public.t_analysis_job aj ON ((obsrate.job = aj.job)))
     JOIN public.t_cached_dataset_folder_paths dfp ON ((aj.dataset_id = dfp.dataset_id)))
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)));


ALTER TABLE public.v_reporter_ion_observation_rate_list_report OWNER TO d3l243;

--
-- Name: TABLE v_reporter_ion_observation_rate_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_reporter_ion_observation_rate_list_report TO readaccess;

