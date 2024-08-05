--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
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
-- Data for Name: t_usage_stats; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_usage_stats (posted_by, last_posting_time, usage_count) FROM stdin;
set_archive_update_task_complete	2024-08-01 19:33:53.956612	304625
set_archive_task_busy	2024-08-01 19:33:53.956612	297313
set_archive_task_complete	2024-08-01 19:33:53.956612	149290
create_psm_job_request	2024-06-12 18:09:06	43
CreatePSMJobRequest	2023-02-24 11:07:11	453
set_archive_update_required	2024-08-01 15:33:01	177814
set_capture_task_busy	2024-08-01 15:33:31	289396
set_capture_task_complete	2024-08-01 15:33:31	144931
set_purge_task_complete	2024-07-30 07:28:41	29674
SetArchiveTaskBusy	2023-02-24 15:26:32	1671314
SetArchiveTaskComplete	2023-02-24 15:20:31	879396
SetArchiveUpdateRequired	2023-02-24 15:49:01	1594913
SetArchiveUpdateTaskBusy	2023-02-24 15:26:31	3634944
SetArchiveUpdateTaskComplete	2023-02-24 15:26:32	2063591
SetCaptureTaskBusy	2023-02-24 15:26:32	1742848
SetCaptureTaskComplete	2023-02-24 15:26:31	885550
SetPurgeTaskComplete	2023-02-27 16:49:15	903729
store_dta_ref_mass_error_stats	2024-07-31 09:59:42	16480
store_qcdm_results	2024-07-16 14:38:28	7945
store_quameter_results	2024-08-01 15:34:19	100379
store_smaqc_results	2024-08-01 15:33:44	8981
StoreDatasetFileInfo	2019-04-02 18:28:21	6
StoreDTARefMassErrorStats	2023-02-27 11:18:50	92358
StoreQCARTResults	2016-07-18 13:28:15	2489
StoreQCDMResults	2023-02-28 23:04:00	212277
StoreQuameterResults	2023-02-24 15:25:37	396122
update_lc_cart_request_assignments	2024-07-13 19:08:47	1
UpdateRequestedRunCopyFactors	2022-09-06 12:11:49	1326
UpdateRequestedRunFactors	2023-02-26 12:57:42	8687
UpdateResearchTeamForCampaign	2023-02-24 16:04:54	1671
UpdateResearchTeamObserver	2022-09-30 10:37:22	256
UpdateSampleRequestAssignments	2022-02-17 08:18:40	233
UpdateUser	2013-03-25 19:01:27	125
set_archive_update_task_busy	2024-08-01 19:33:53.956612	600530
update_requested_run_blocking_and_factors	2024-07-26 12:55:15	806
update_requested_run_factors	2024-07-26 12:55:15	917
update_research_team_for_campaign	2024-08-01 10:06:04	225
update_research_team_observer	2023-11-01 11:13:14	5
update_sample_request_assignments	2023-04-10 10:47:28	1
UpdateAnalysisJobProcessorGroupAssociations	2014-01-24 15:19:43	2
UpdateAnalysisJobProcessorGroupMembership	2013-01-29 17:40:39	1
UpdateAnalysisJobs	2022-10-19 10:31:36	282
UpdateAnalysisJobStateNameCached	2023-02-22 22:03:05	1789
UpdateAnalysisJobToolNameCached	2023-02-22 22:03:10	1388
update_dataset_file_info_xml	2024-08-01 21:00:22.474228	145380
UpdateCartParameters	2023-02-27 13:19:56	873444
UpdateDatasetDispositions	2023-02-25 22:00:50	22011
UpdateDatasetDispositionsByName	2023-02-25 22:00:50	1794
UpdateDatasetFileInfoXML	2023-02-24 15:26:31	866164
UpdateDatasets	2015-10-07 13:35:56	34
update_analysis_job_state_name_cached	2024-08-02 22:03:23.348831	225
update_analysis_job_tool_name_cached	2024-08-02 22:03:27.123817	225
update_eus_proposals_from_eus_imports	2024-08-04 06:15:24.929266	527
StoreSMAQCResults	2023-02-27 16:58:37	77970
update_eus_users_from_eus_imports	2024-08-04 06:15:47.748334	531
update_analysis_job_processor_group_membership	2024-06-04 14:50:59	8
update_eus_instruments_from_eus_imports	2024-08-04 06:16:23.197328	529
update_analysis_jobs	2024-04-03 08:54:02	3
update_cart_parameters	2024-08-01 15:16:42	222396
update_dataset_dispositions	2024-08-01 14:12:27	2897
update_dataset_dispositions_by_name	2024-08-01 12:19:46	540
update_eus_info_from_eus_imports	2024-01-02 18:50:13	1
update_instrument_group_allowed_dataset_type	2024-07-23 13:44:01	71
update_notification_user_registration	2024-04-03 08:00:11	1
update_organism_list_for_biomaterial	2024-03-12 22:27:22	422
UpdateEUSInfoFromEUSImports	2021-05-14 10:38:52	6
UpdateEUSInstrumentsFromEUSImports	2023-02-24 06:15:30	3714
UpdateEUSProposalsFromEUSImports	2023-02-24 06:15:10	4208
UpdateEUSUsersFromEUSImports	2023-02-24 06:15:30	4210
UpdateInstrumentGroupAllowedDatasetType	2019-06-03 17:46:10	18
UpdateLCCartBlockAssignments	2012-05-03 10:05:10	8
update_requested_run_admin	2024-08-01 08:57:04	403
update_requested_run_assignments	2024-08-01 15:34:01	3890
update_requested_run_batch_parameters	2024-07-26 12:55:15	688
UpdateLCCartRequestAssignments	2020-10-05 14:05:00	1009
UpdateMaterialLocations	2017-11-01 14:36:14	2
UpdateNotificationUserRegistration	2019-09-18 11:50:15	13
UpdateOrganismListForBiomaterial	2023-02-15 14:33:30	12134
UpdateRequestedRunAdmin	2023-02-22 10:42:51	1749
UpdateRequestedRunAssignments	2023-02-24 16:35:23	11234
UpdateRequestedRunBatchParameters	2023-02-26 12:57:42	6051
UpdateRequestedRunBlockingAndFactors	2023-02-26 12:57:42	7354
\.


--
-- PostgreSQL database dump complete
--

