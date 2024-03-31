--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: task; Type: TABLE DATA; Schema: timetable; Owner: d3l243
--

COPY timetable.task (task_id, chain_id, task_order, task_name, kind, command, run_as, database_connection, ignore_error, autonomous, timeout) FROM stdin;
2	3	10	\N	SQL	VACUUM	\N	\N	t	t	0
3	4	10	\N	SQL	TRUNCATE timetable.log	\N	\N	t	t	0
29	22	20	Cache instruments with QC metrics	SQL	CALL cache_instruments_with_qc_metrics (_infoOnly => false);	\N	\N	f	t	0
14	13	20	Auto reset failed jobs	SQL	CALL auto_reset_failed_jobs (_infoOnly => false);	\N	\N	f	t	0
8	11	10	Sleep 25 seconds	BUILTIN	Sleep	\N	\N	f	f	0
4	6	10	Add missing predefined jobs	SQL	CALL add_missing_predefined_jobs (\r\n    _infoOnly => false, \r\n    _maxDatasetsToProcess => 0, \r\n    _dayCountForRecentDatasets => 30,\r\n    _instrumentSkipList => '12T_FTICR_B, 15T_FTICR, 15T_FTICR_Imaging, Agilent_GC_MS_01, Agilent_GC_MS_02, Agilent_QQQ_04, GCQE01, IMS05_AgQTOF03, IMS07_AgTOF04, IMS08_AgQTOF05, IMS09_AgQToF06, IMS10_AgQTOF07, SynaptG2_01',\r\n    _ignoreJobsCreatedBeforeDisposition => true);	\N	\N	f	t	0
5	6	20	Add missing MASIC jobs	SQL	CALL add_missing_predefined_jobs (\r\n    _infoOnly => false,\r\n    _maxDatasetsToProcess => 0, \r\n    _dayCountForRecentDatasets => 180,\r\n    _instrumentSkipList => '12T_FTICR_B, 15T_FTICR, 15T_FTICR_Imaging, Agilent_GC_MS_01, Agilent_GC_MS_02, Agilent_QQQ_04, GCQE01, IMS05_AgQTOF03, IMS07_AgTOF04, IMS08_AgQTOF05, IMS09_AgQToF06, IMS10_AgQTOF07, SynaptG2_01',\r\n    _analysisToolNameFilter => 'MASIC%',\r\n    _excludeDatasetsNotReleased => true,\r\n    _ignoreJobsCreatedBeforeDisposition => false,\r\n    _showDebug => false,\r\n    _datasetIDFilterList => '',\r\n    _datasetNameIgnoreExistingJobs => '');	\N	\N	f	t	0
6	8	10	Auto add BOM tracking datasets	SQL	CALL add_bom_tracking_datasets ('next', '', 'add', 'D3E154');	\N	\N	f	t	0
7	10	10	Auto annotate broken instrument long intervals	SQL	CALL auto_annotate_broken_instrument_long_intervals (_targetDate => null, _infoOnly => false);	\N	\N	f	t	0
10	11	20	Auto define WPs for EUS requested runs	SQL	CALL auto_define_wps_for_eus_requested_runs (_mostRecentMonths => 6, _infoOnly => false);	\N	\N	f	t	0
20	14	20	Auto skip failed UIMF calibration	SQL	UPDATE cap.T_Task_Steps\r\nSET State = 5,\r\n    Completion_Code = 0,\r\n    Completion_Message = 'Demultiplexed, but skipped calibration'\r\nWHERE (State = 6) AND\r\n      (Tool = 'ImsDeMultiplex') AND\r\n      (Evaluation_Message LIKE 'De-multiplexed but Calibration failed%') AND\r\n      (Completion_Message LIKE 'Error calibrating UIMF file%');	\N	\N	f	t	0
30	23	10	Sleep 20 seconds	BUILTIN	Sleep	\N	\N	f	f	0
22	15	20	Auto define superseded proposals	SQL	CALL auto_define_superseded_eus_proposals (_infoOnly => false);	\N	\N	f	t	0
13	13	10	Sleep 40 seconds	BUILTIN	Sleep	\N	\N	f	f	0
19	14	10	Sleep 53 seconds	BUILTIN	Sleep	\N	\N	f	f	0
21	15	10	Sleep 46 seconds	BUILTIN	Sleep	\N	\N	f	f	0
23	16	10	Sleep 39 seconds	BUILTIN	Sleep	\N	\N	f	f	0
24	16	20	Auto update job priorities	SQL	CALL auto_update_job_priorities (_infoOnly => false);	\N	\N	f	t	0
25	17	10	Auto update QC_Shew dataset rating	SQL	CALL auto_update_dataset_rating_via_qc_metrics (\r\n   _campaignName => 'QC-Shew-Standard', \r\n   _experimentExclusion => '%Intact%',\r\n   _datasetCreatedMinimum => '2012-10-01', \r\n   _infoOnly => false);	\N	\N	f	t	0
26	21	10	Sleep 40 seconds	BUILTIN	Sleep	\N	\N	f	f	0
27	21	20	Backfill pipeline jobs	SQL	CALL backfill_pipeline_jobs (_infoOnly => false);	\N	\N	f	t	0
28	22	10	Sleep 38 seconds	BUILTIN	Sleep	\N	\N	f	f	0
31	23	20	Check data integrity	SQL	CALL check_data_integrity (_logErrors => true);	\N	\N	f	t	0
32	24	10	Sleep 27 seconds	BUILTIN	Sleep	\N	\N	f	f	0
33	24	20	Check capture tasks for MyEMSL upload errors	SQL	CALL cap.check_for_myemsl_errors (_mostRecentDays => 2, _logErrors => true);	\N	\N	f	t	0
34	24	30	Check data packages for MyEMSL upload errors	SQL	CALL dpkg.check_for_myemsl_errors (_mostRecentDays => 2, _logErrors => true);	\N	\N	f	t	0
36	25	20	Cleanup operating Logs, public	SQL	CALL public.cleanup_operating_logs (\r\n        _logRetentionIntervalHours => 336,\r\n        _eventLogRetentionIntervalDays => 365);	\N	\N	f	t	0
37	25	30	Cleanup operating logs, sw	SQL	CALL sw.cleanup_operating_logs (\r\n        _infoHoldoffWeeks => 3,\r\n        _logRetentionIntervalDays => 365);	\N	\N	f	t	0
38	25	40	Cleanup operating logs, cap	SQL	CALL cap.cleanup_operating_logs (\r\n        _infoHoldoffWeeks => 3, \r\n        _logRetentionIntervalDays => 180);	\N	\N	f	t	0
39	25	50	Cleanup operating logs, dpkg	SQL	CALL dpkg.move_historic_log_entries (\r\n        _infoHoldoffWeeks => 3);	\N	\N	f	t	0
35	25	10	Sleep 15 seconds	BUILTIN	Sleep	\N	\N	f	f	0
40	26	10	Cleanup old tasks	SQL	CALL cap.remove_old_tasks (_infoOnly => false);	\N	\N	f	t	0
42	26	20	Update capture task stats	SQL	CALL cap.update_capture_task_stats (_infoOnly => false);	\N	\N	f	t	0
43	26	30	Delete old tasks from history	SQL	CALL cap.delete_old_tasks_from_history (_infoOnly => false);	\N	\N	f	t	0
44	27	10	Sleep 35 seconds	BUILTIN	Sleep	\N	\N	f	f	0
45	27	20	Cleanup old jobs	SQL	CALL sw.remove_old_jobs (_validateJobStepSuccess => true);	\N	\N	f	t	0
46	27	30	Update pipeline job stats	SQL	CALL sw.update_pipeline_job_stats (_infoOnly => false);	\N	\N	f	t	0
47	27	40	Delete old jobs from history	SQL	CALL sw.delete_old_jobs_from_history (_infoOnly => false);	\N	\N	f	t	0
49	29	10	Sleep 15 seconds	BUILTIN	Sleep	\N	\N	f	f	0
50	29	20	Create pending predefined jobs	SQL	CALL create_pending_predefined_analysis_tasks (_infoOnly => false);	\N	\N	f	t	0
89	52	10	Sleep 42 seconds	BUILTIN	Sleep	\N	\N	f	f	0
52	31	10	Sleep 10 seconds	BUILTIN	Sleep	\N	\N	f	f	0
53	31	20	Delete orphaned capture jobs	SQL	CALL cap.delete_orphaned_tasks (_infoOnly => false);	\N	\N	f	t	0
90	52	20	Update cached dataset folder paths, all datasets	SQL	CALL update_cached_dataset_folder_paths (_processingMode => 2);	\N	\N	f	t	0
48	28	10	Clear data package manager errors	SQL	DELETE FROM dpkg.T_Log_Entries\r\nWHERE (message LIKE '%has an existing metadata file between 2 and 6.5 days old%' OR\r\n   message LIKE '%has not been validated in the archive after 5 days; %' OR\r\n   message LIKE '%is not available in MyEMSL after 24 hours; see %' OR\r\n   message LIKE '%was previously uploaded to MyEMSL, yet Simple Search did not return any files for this dataset%Skipping this data package %')\r\n    AND (type = 'error');	\N	\N	f	t	0
74	45	20	Set external dataset purge priority	SQL	CALL set_external_dataset_purge_priority (_infoOnly => false);	\N	\N	f	t	0
51	30	10	Delete old historic DMS DB logs	SQL	CALL logdms.delete_old_events_and_historic_logs (_infoOnly => false);	\N	\N	f	t	0
54	32	10	Disable archive-dependent step tools	SQL	CALL cap.enable_disable_archive_step_tools (_enable => false, _disableComment => 'Disabled for scheduled archive maintenance');	\N	\N	f	t	0
55	33	10	Disable MSGFPlus	SQL	CALL sw.enable_disable_step_tool_for_debugging (_tool => 'MSGFPlus', _debugMode => true);	\N	\N	f	t	0
56	34	10	Requested run batch events	SQL	CALL make_notification_requested_run_batch_events ();	\N	\N	f	t	0
75	46	10	Sleep 24 seconds	BUILTIN	Sleep	\N	\N	f	f	0
60	35	10	Enable archive update	SQL	CALL cap.enable_disable_task_step_tool_for_debugging (_tool => 'ArchiveUpdate', _debugMode => false);	\N	\N	f	t	0
61	36	10	Enable archive-dependent step tools	SQL	CALL cap.enable_disable_archive_step_tools (_enable => 1, _disableComment => 'Disabled for scheduled archive maintenance');	\N	\N	f	t	0
62	37	10	Re-enable MSGFPlus	SQL	CALL sw.enable_disable_step_tool_for_debugging ('MSGFPlus', _debugMode => false);	\N	\N	f	t	0
63	38	10	Sleep 5 seconds	BUILTIN	Sleep	\N	\N	f	f	0
64	38	20	Find stale MyEMSL uploads	SQL	CALL cap.find_stale_myemsl_uploads (_infoOnly => false);	\N	\N	f	t	0
76	46	20	Store weekly project usage stats	SQL	CALL store_project_usage_stats (_windowDays => 7, _endDate => null, _infoOnly => false);	\N	\N	f	t	0
66	39	20	Reset failed dataset capture tasks	SQL	CALL reset_failed_dataset_capture_tasks (_resetHoldoffHours => 2, _infoOnly => false);	\N	\N	f	t	0
67	40	10	Reset failed dataset purge tasks	SQL	CALL reset_failed_dataset_purge_tasks (\r\n               _resetHoldoffHours => 1.5,\r\n               _infoOnly => false);	\N	\N	f	t	0
68	41	10	Reset failed pipeline job managers	SQL	CALL sw.reset_failed_managers (_infoOnly => false);	\N	\N	f	t	0
70	42	20	Reset failed MyEMSL uploads	SQL	CALL cap.reset_failed_myemsl_uploads (_infoOnly => false, _maxJobsToReset => 0);	\N	\N	f	t	0
69	42	10	Sleep 15 seconds	BUILTIN	Sleep	\N	\N	f	f	0
65	39	10	Sleep 32 seconds	BUILTIN	Sleep	\N	\N	f	f	0
77	47	10	Sleep 14 seconds	BUILTIN	Sleep	\N	\N	f	f	0
57	34	20	Analysis job request events	SQL	CALL make_notification_analysis_job_request_events ();	\N	\N	f	t	0
58	34	30	Sample prep request events	SQL	CALL make_notification_sample_prep_request_events ();	\N	\N	f	t	0
59	34	40	Dataset events	SQL	CALL make_notification_dataset_events ();	\N	\N	f	t	0
71	43	10	Retire stale campaigns	SQL	CALL retire_stale_campaigns (_infoOnly => false);	\N	\N	f	t	0
72	44	10	Retire LC columns	SQL	CALL retire_stale_lc_columns (_infoOnly => false);	\N	\N	f	t	0
73	45	10	Sleep 17 seconds	BUILTIN	Sleep	\N	\N	f	f	0
78	47	20	Synchronize analysis job requests with jobs	SQL	CALL sync_job_param_and_settings_with_request (_recentRequestDays => 14, _infoOnly => false);	\N	\N	f	t	0
79	48	10	Sleep 12 seconds	BUILTIN	Sleep	\N	\N	f	f	0
80	48	20	UpdateBionetHostStatus	SQL	CALL update_bionet_host_status (_infoOnly => false);	\N	\N	f	t	0
81	49	10	Update cached analysis job state name	SQL	CALL update_analysis_job_state_name_cached ();	\N	\N	f	t	0
82	49	20	Update cached analysis job tool name	SQL	CALL update_analysis_job_tool_name_cached ();	\N	\N	f	t	0
83	50	10	Sleep 36 seconds	BUILTIN	Sleep	\N	\N	f	f	0
84	50	20	Update cached dataset folder paths, mode 0	SQL	CALL update_cached_dataset_folder_paths (_processingMode => 0);	\N	\N	f	t	0
85	50	30	Update cached dataset links, mode 0	SQL	CALL update_cached_dataset_links (_processingMode => 0);	\N	\N	f	t	0
86	51	10	Sleep 39 seconds	BUILTIN	Sleep	\N	\N	f	f	0
87	51	20	Update cached dataset folder paths, mode 1	SQL	CALL update_cached_dataset_folder_paths (_processingMode => 1);	\N	\N	f	t	0
88	51	30	Update cached dataset links, mode 1	SQL	CALL update_cached_dataset_links (_processingMode => 1);	\N	\N	f	t	0
91	52	30	Update cached dataset links, mode 2	SQL	CALL update_cached_dataset_links (_processingMode => 2);	\N	\N	f	t	0
92	53	10	Sleep 11 seconds	BUILTIN	Sleep	\N	\N	f	f	0
93	53	20	Update cached dataset folder paths, full refresh	SQL	CALL update_cached_dataset_folder_paths (_processingMode => 3);	\N	\N	f	t	0
94	53	30	Update cached dataset links, full refresh	SQL	CALL update_cached_dataset_links (_processingMode => 3);	\N	\N	f	t	0
95	54	10	Sleep 40 seconds	BUILTIN	Sleep	\N	\N	f	f	0
116	64	20	Update cached secondary sep usage	SQL	CALL update_cached_secondary_sep_usage ();	\N	\N	f	t	0
98	55	10	Sleep 17 seconds	BUILTIN	Sleep	\N	\N	f	f	0
100	56	10	Sleep 18 seconds	BUILTIN	Sleep	\N	\N	f	f	0
101	56	20	Update cached experiment components	SQL	CALL update_cached_experiment_component_names (_experimentID => 0, _infoOnly => false);	\N	\N	f	t	0
96	54	20	Update cached dataset instruments	SQL	CALL update_cached_dataset_instruments (_processingMode => 1, _infoOnly => false);	\N	\N	f	t	0
99	55	20	Add new cached dataset instruments	SQL	CALL update_cached_dataset_instruments (_processingMode => 0, _infoOnly => false);	\N	\N	f	t	0
104	57	10	Sleep 35 seconds	BUILTIN	Sleep	\N	\N	f	f	0
105	57	20	Update cached instrument usage by proposal	SQL	CALL update_cached_instrument_usage_by_proposal ();	\N	\N	f	t	0
106	58	10	Sleep 27 seconds	BUILTIN	Sleep	\N	\N	f	f	0
107	58	20	Update cached existing jobs	SQL	CALL update_cached_job_request_existing_jobs (\r\n    _processingMode => 0,\r\n    _requestId => 0,\r\n    _jobSearchHours => 350,\r\n    _infoOnly => false);	\N	\N	f	t	0
117	65	10	Update cached tissue names	SQL	CALL ont.update_cached_bto_names_proc (_infoOnly => false);	\N	\N	f	t	0
109	60	10	Sleep 36 seconds	BUILTIN	Sleep	\N	\N	f	f	0
110	60	20	Update cached RRB stats	SQL	CALL update_cached_requested_run_batch_stats (_batchID => 0, _fullRefresh => false);	\N	\N	f	t	0
111	61	10	Sleep 37 seconds	BUILTIN	Sleep	\N	\N	f	f	0
112	61	20	Update cached RRB stats (full refresh)	SQL	CALL update_cached_requested_run_batch_stats (_batchID => 0, _fullRefresh => true);	\N	\N	f	t	0
113	62	10	Update cached requested run users	SQL	CALL update_cached_requested_run_eus_users (_requestID => 0);	\N	\N	f	t	0
114	63	10	Update sample prep request items	SQL	CALL update_all_sample_prep_request_items ();	\N	\N	f	t	0
115	64	10	Sleep 25 seconds	BUILTIN	Sleep	\N	\N	f	f	0
118	66	10	Sleep 30 seconds	BUILTIN	Sleep	\N	\N	f	f	0
119	66	20	Process capture tasks	SQL	CALL cap.update_task_context (_bypassDMS => false);	\N	\N	f	t	0
120	67	10	Sleep 17 seconds	BUILTIN	Sleep	\N	\N	f	f	0
127	71	10	Update dataset interval for multiple instruments	SQL	CALL update_dataset_interval_for_multiple_instruments (\r\n           _daysToProcess => 60,\r\n           _updateEMSLInstrumentUsage => false);	\N	\N	f	t	0
122	68	10	Sleep 42 seconds	BUILTIN	Sleep	\N	\N	f	f	0
123	68	20	Update charge codes from warehouse	SQL	CALL update_charge_codes_from_warehouse (_infoOnly => false);	\N	\N	f	t	0
124	69	10	Update data package EUS info	SQL	CALL dpkg.update_data_package_eus_info ('0');	\N	\N	f	t	0
125	70	10	Sleep 10 seconds	BUILTIN	Sleep	\N	\N	f	f	0
121	67	20	Update charge code usage	SQL	CALL public.update_charge_code_usage_proc (_infoOnly => false);	\N	\N	f	t	0
108	59	10	Update cached NCBI taxonomy	SQL	CALL ont.update_cached_ncbi_taxonomy_proc (_deleteExtras => true, _infoOnly => false);	\N	\N	f	t	0
128	72	10	Sleep 10 seconds	BUILTIN	Sleep	\N	\N	f	f	0
129	72	20	DMS user update daily	SQL	CALL update_users_from_warehouse (_infoOnly => false);	\N	\N	f	t	0
130	73	10	Update EUS proposals	SQL	CALL update_eus_proposals_from_eus_imports ();	\N	\N	f	t	0
131	73	20	Update EUS users	SQL	CALL update_eus_users_from_eus_imports ();	\N	\N	f	t	0
132	73	30	Update EUS instruments	SQL	CALL update_eus_instruments_from_eus_imports ();	\N	\N	f	t	0
133	74	10	Sleep 57 seconds	BUILTIN	Sleep	\N	\N	f	f	0
134	74	20	Update EUS requested run WP	SQL	CALL update_eus_requested_run_wp (_infoOnly => false);	\N	\N	f	t	0
135	75	10	Sleep 22 seconds	BUILTIN	Sleep	\N	\N	f	f	0
136	75	20	Update experiment group member count	SQL	CALL update_experiment_group_member_count(_groupID => 0);	\N	\N	f	t	0
137	76	10	Sleep 52 seconds	BUILTIN	Sleep	\N	\N	f	f	0
138	76	20	Update experiment usage	SQL	CALL update_experiment_usage (_infoOnly => false);	\N	\N	f	t	0
139	77	10	Update job step processing stats	SQL	CALL update_job_step_processing_stats (_infoOnly => false);	\N	\N	f	t	0
140	78	10	Update missed DMS file info	SQL	CALL cap.update_missed_dms_file_info (\r\n                 _deleteFromTableOnSuccess => true,\r\n                 _replaceExistingData => false,\r\n                 _infoOnly => false);	\N	\N	f	t	0
141	79	10	Update missed MyEMSLState info	SQL	CALL cap.update_missed_myemsl_state_values (_windowDays => 30, _infoOnly => false);	\N	\N	f	t	0
142	80	10	Process pipeline jobs	SQL	CALL sw.update_context (_infoOnly => false);	\N	\N	f	t	0
143	80	20	Update overall job progress	SQL	CALL update_job_progress (_mostRecentDays => 32, _job => 0, _infoOnly => false);	\N	\N	f	t	0
144	81	10	Sleep 22 seconds	BUILTIN	Sleep	\N	\N	f	f	0
145	81	20	Update prep LC run work packages	SQL	CALL update_prep_lc_run_work_package_list (0);	\N	\N	f	t	0
146	82	10	Update capture pipeline status history	SQL	CALL cap.update_task_step_status_history (_minimumTimeIntervalMinutes => 4);	\N	\N	f	t	0
147	83	10	Update job status history	SQL	CALL update_job_status_history ();	\N	\N	f	t	0
148	83	20	Update requested run status history	SQL	CALL update_requested_run_status_history ();	\N	\N	f	t	0
149	84	10	Update job step status history	SQL	CALL sw.update_job_step_status_history (_minimumTimeIntervalMinutes => 4);	\N	\N	f	t	0
150	84	20	Update machine status history	SQL	CALL sw.update_machine_status_history (_minimumTimeIntervalHours => 1);	\N	\N	f	t	0
151	85	10	Sleep 25 seconds	BUILTIN	Sleep	\N	\N	f	f	0
153	86	10	Sleep 4 seconds	BUILTIN	Sleep	\N	\N	f	f	0
154	86	20	Update cached statistics	SQL	CALL update_cached_statistics (\r\n    _updateParamSettingsFileCounts => true,\r\n    _updateGeneralStatistics => true,\r\n    _updateJobRequestStatistics => true);	\N	\N	f	t	0
155	86	30	Update campaign tracking	SQL	CALL update_campaign_tracking ();	\N	\N	f	t	0
156	86	40	Update biomaterial tracking	SQL	CALL update_biomaterial_tracking ();	\N	\N	f	t	0
157	87	10	Sleep 47 seconds	BUILTIN	Sleep	\N	\N	f	f	0
158	87	20	Process waiting special processing jobs	SQL	CALL process_waiting_special_proc_jobs (_infoOnly => false);	\N	\N	f	t	0
159	88	10	Validate job and dataset states	SQL	CALL validate_job_dataset_states (_infoOnly => false);	\N	\N	f	t	0
126	70	20	Update dataset interval and instrument usage for multiple instruments	SQL	CALL update_dataset_interval_for_multiple_instruments (\r\n           _daysToProcess => 180,\r\n           _updateEMSLInstrumentUsage => true);	\N	\N	f	t	0
152	85	20	Update tissue usage	SQL	CALL ont.update_bto_usage_proc (_infoOnly => false);	\N	\N	f	t	0
\.


--
-- Name: task_task_id_seq; Type: SEQUENCE SET; Schema: timetable; Owner: d3l243
--

SELECT pg_catalog.setval('timetable.task_task_id_seq', 159, true);


--
-- PostgreSQL database dump complete
--

