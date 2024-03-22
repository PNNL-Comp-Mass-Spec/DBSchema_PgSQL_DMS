--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
-- Dumped by pg_dump version 16.1

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
41	26	20	Cleanup old tasks	SQL	CALL cap.remove_old_tasks (_infoOnly => false);	\N	\N	f	t	0
42	26	30	Update capture task stats	SQL	CALL cap.update_capture_task_stats (_infoOnly => false);	\N	\N	f	t	0
43	26	40	Delete old tasks from history	SQL	CALL cap.delete_old_tasks_from_history (_infoOnly => false);	\N	\N	f	t	0
44	27	10	Sleep 35 seconds	BUILTIN	Sleep	\N	\N	f	f	0
45	27	20	Cleanup old jobs	SQL	CALL sw.remove_old_jobs (_validateJobStepSuccess => true);	\N	\N	f	t	0
46	27	30	Update pipeline job stats	SQL	CALL sw.update_pipeline_job_stats (_infoOnly => false);	\N	\N	f	t	0
47	27	40	Delete old jobs from history	SQL	CALL sw.delete_old_jobs_from_history (_infoOnly => false);	\N	\N	f	t	0
49	29	10	Sleep 15 seconds	BUILTIN	Sleep	\N	\N	f	f	0
50	29	20	Create pending predefined jobs	SQL	CALL create_pending_predefined_analysis_tasks (_infoOnly => false);	\N	\N	f	t	0
52	31	10	Sleep 10 seconds	BUILTIN	Sleep	\N	\N	f	f	0
53	31	20	Delete orphaned capture jobs	SQL	CALL cap.delete_orphaned_tasks (_infoOnly => false);	\N	\N	f	t	0
48	28	10	Clear data package manager errors	SQL	DELETE FROM dpkg.T_Log_Entries\r\nWHERE (message LIKE '%has an existing metadata file between 2 and 6.5 days old%' OR\r\n   message LIKE '%has not been validated in the archive after 5 days; %' OR\r\n   message LIKE '%is not available in MyEMSL after 24 hours; see %' OR\r\n   message LIKE '%was previously uploaded to MyEMSL, yet Simple Search did not return any files for this dataset%Skipping this data package %')\r\n    AND (type = 'error');	\N	\N	f	t	0
51	30	10	Delete old historic DMS DB logs	SQL	CALL logdms.delete_old_events_and_historic_logs (_infoOnly => false);	\N	\N	f	t	0
54	32	10	Disable archive-dependent step tools	SQL	CALL cap.enable_disable_archive_step_tools (_enable => false, _disableComment => 'Disabled for scheduled archive maintenance');	\N	\N	f	t	0
55	33	10	Disable MSGFPlus	SQL	CALL sw.enable_disable_step_tool_for_debugging (_tool => 'MSGFPlus', _debugMode => true);	\N	\N	f	t	0
56	34	10	Requested run batch events	SQL	CALL make_notification_requested_run_batch_events ();	\N	\N	f	t	0
57	34	20	Requested run batch events	SQL	CALL make_notification_requested_run_batch_events ();	\N	\N	f	t	0
58	34	30	Step Name	SQL	CALL make_notification_sample_prep_request_events ();	\N	\N	f	t	0
59	34	40	Step Name	SQL	CALL make_notification_dataset_events ();	\N	\N	f	t	0
60	35	10	Enable archive update	SQL	CALL cap.enable_disable_task_step_tool_for_debugging (_tool => 'ArchiveUpdate', _debugMode => false);	\N	\N	f	t	0
61	36	10	Enable archive-dependent step tools	SQL	CALL cap.enable_disable_archive_step_tools (_enable => 1, _disableComment => 'Disabled for scheduled archive maintenance');	\N	\N	f	t	0
62	37	10	Re-enable MSGFPlus	SQL	CALL sw.enable_disable_step_tool_for_debugging ('MSGFPlus', _debugMode => false);	\N	\N	f	t	0
63	38	10	Sleep 5 seconds	BUILTIN	Sleep	\N	\N	f	f	0
64	38	20	Find stale MyEMSL uploads	SQL	CALL cap.find_stale_myemsl_uploads (_infoOnly => false);	\N	\N	f	t	0
65	39	10	Sleep 7 seconds	BUILTIN	Sleep	\N	\N	f	f	0
66	39	20	Reset failed dataset capture tasks	SQL	CALL reset_failed_dataset_capture_tasks (_resetHoldoffHours => 2, _infoOnly => false);	\N	\N	f	t	0
\.


--
-- Name: task_task_id_seq; Type: SEQUENCE SET; Schema: timetable; Owner: d3l243
--

SELECT pg_catalog.setval('timetable.task_task_id_seq', 66, true);


--
-- PostgreSQL database dump complete
--

