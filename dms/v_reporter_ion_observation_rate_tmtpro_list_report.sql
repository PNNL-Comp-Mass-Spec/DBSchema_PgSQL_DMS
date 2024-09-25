--
-- Name: v_reporter_ion_observation_rate_tmtpro_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_reporter_ion_observation_rate_tmtpro_list_report AS
 SELECT obsrate.dataset_id,
    ds.dataset,
    obsrate.reporter_ion,
    ((((((dfp.dataset_url)::text || '/'::text) || (aj.results_folder_name)::text) || '/'::text) || (ds.dataset)::text) || '_RepIonObsRateHighAbundance.png'::text) AS observation_rate_link,
    ((((((dfp.dataset_url)::text || '/'::text) || (aj.results_folder_name)::text) || '/'::text) || (ds.dataset)::text) || '_RepIonStatsHighAbundance.png'::text) AS intensity_stats_link,
    inst.instrument,
    ds.acq_length_minutes AS acq_length,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    COALESCE(ds.acq_time_end, rr.request_run_finish) AS acq_end,
    rr.request_id AS request,
    rr.batch_id AS batch,
    obsrate.job,
    aj.param_file_name AS param_file,
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
    obsrate.channel17,
    obsrate.channel18,
    obsrate2.channel19,
    obsrate2.channel20,
    obsrate2.channel21,
    obsrate2.channel22,
    obsrate2.channel23,
    obsrate2.channel24,
    obsrate2.channel25,
    obsrate2.channel26,
    obsrate2.channel27,
    obsrate2.channel28,
    obsrate2.channel29,
    obsrate2.channel30,
    obsrate2.channel31,
    obsrate2.channel32,
    obsrate2.channel33,
    obsrate2.channel34,
    obsrate2.channel35,
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
    obsrate.channel17_median_intensity AS channel17_intensity,
    obsrate.channel18_median_intensity AS channel18_intensity,
    obsrate2.channel19_median_intensity AS channel19_intensity,
    obsrate2.channel20_median_intensity AS channel20_intensity,
    obsrate2.channel21_median_intensity AS channel21_intensity,
    obsrate2.channel22_median_intensity AS channel22_intensity,
    obsrate2.channel23_median_intensity AS channel23_intensity,
    obsrate2.channel24_median_intensity AS channel24_intensity,
    obsrate2.channel25_median_intensity AS channel25_intensity,
    obsrate2.channel26_median_intensity AS channel26_intensity,
    obsrate2.channel27_median_intensity AS channel27_intensity,
    obsrate2.channel28_median_intensity AS channel28_intensity,
    obsrate2.channel29_median_intensity AS channel29_intensity,
    obsrate2.channel30_median_intensity AS channel30_intensity,
    obsrate2.channel31_median_intensity AS channel31_intensity,
    obsrate2.channel32_median_intensity AS channel32_intensity,
    obsrate2.channel33_median_intensity AS channel33_intensity,
    obsrate2.channel34_median_intensity AS channel34_intensity,
    obsrate2.channel35_median_intensity AS channel35_intensity,
    obsrate.entered
   FROM ((((((public.t_reporter_ion_observation_rates obsrate
     JOIN public.t_analysis_job aj ON ((obsrate.job = aj.job)))
     JOIN public.t_cached_dataset_folder_paths dfp ON ((aj.dataset_id = dfp.dataset_id)))
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     LEFT JOIN public.t_reporter_ion_observation_rates_addnl obsrate2 ON ((obsrate.job = obsrate2.job)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
  WHERE (obsrate.reporter_ion OPERATOR(public.=) ANY (ARRAY['TMT16'::public.citext, 'TMT18'::public.citext, 'TMT32'::public.citext, 'TMT35'::public.citext]));


ALTER VIEW public.v_reporter_ion_observation_rate_tmtpro_list_report OWNER TO d3l243;

--
-- Name: TABLE v_reporter_ion_observation_rate_tmtpro_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_reporter_ion_observation_rate_tmtpro_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_reporter_ion_observation_rate_tmtpro_list_report TO writeaccess;

