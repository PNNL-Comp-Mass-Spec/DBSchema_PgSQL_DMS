--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: t_processor_tool; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_processor_tool (processor_name, tool_name, priority, enabled, comment, last_affected) FROM stdin;
Mash-01_CTM	DatasetInfo	4	0	Decommissioned	2017-09-22 16:34:19
Mash-01_CTM	SourceFileRename	3	0	Decommissioned	2014-02-21 09:46:31
Mash-02_CTM	DatasetInfo	4	0	Decommissioned	2017-09-22 16:34:20
Mash-02_CTM	SourceFileRename	3	0	Decommissioned	2014-02-21 09:46:31
Mash-03_CTM	DatasetInfo	4	0	Decommissioned	2017-09-22 16:34:20
Mash-03_CTM	SourceFileRename	3	0	Decommissioned	2014-02-21 09:46:31
Mash-04_CTM	DatasetInfo	4	0	Decommissioned	2017-09-22 16:34:20
Mash-04_CTM	SourceFileRename	3	0	Decommissioned	2014-02-21 09:46:31
Mash-05_CTM	DatasetInfo	4	0	Decommissioned	2017-09-22 16:34:20
Mash-05_CTM	SourceFileRename	3	0	Decommissioned	2014-02-21 09:46:32
Mash-06_CTM	DatasetInfo	4	0	Decommissioned	2017-09-22 16:34:20
Mash-06_CTM	SourceFileRename	3	0	Decommissioned	2014-02-21 09:46:32
Monroe_CTM	ArchiveStatusCheck	3	0		2018-01-26 14:53:48
Monroe_CTM	ArchiveUpdate	4	0		2025-04-19 08:21:46.452337
Monroe_CTM	ArchiveUpdateTest	4	-1		2013-09-10 17:32:58
Monroe_CTM	ArchiveVerify	3	0	MyEMSL is offline	2024-10-09 18:37:42.211466
Monroe_CTM	DatasetArchive	2	0		2025-06-13 16:41:51.710259
Monroe_CTM	DatasetCapture	2	0		2025-11-03 19:29:45.977975
Monroe_CTM	DatasetInfo	3	0	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Monroe_CTM	DatasetIntegrity	3	0	Runs simple file/folder checks	2025-07-31 18:08:45.826404
Monroe_CTM	DatasetQuality	2	0	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Monroe_CTM	ImsDeMultiplex	3	0		2025-01-10 18:37:18.506873
Monroe_CTM	LCDatasetCapture	2	0		2025-01-08 16:25:38.820219
Monroe_CTM	LCDatasetInfo	3	0		2024-02-12 14:21:43
Monroe_CTM	SourceFileRename	3	0		2019-07-17 11:33:27
Proto-10_CTM	ArchiveUpdate	4	0	Offline	2017-07-03 13:49:08
Proto-10_CTM	DatasetArchive	3	0	Offline	2017-07-03 13:49:16
Proto-10_CTM	DatasetCapture	2	1	Will only capture IMS_TOF datasets; see T_Processor_Instrument	2025-11-03 19:29:45.977975
Proto-10_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-10_CTM_2	ArchiveUpdate	4	0	Offline	2016-06-22 18:28:25
Proto-10_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-11_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-11_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-11_CTM	DatasetCapture	3	1		2025-11-03 19:29:45.977975
Proto-11_CTM	LCDatasetCapture	3	1		2025-01-08 16:25:38.820219
Proto-11_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-11_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-11_CTM_2	DatasetCapture	2	1		2025-11-03 19:29:45.977975
Proto-11_CTM_2	LCDatasetCapture	2	1		2025-01-08 16:25:38.820219
Proto-11_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-2_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-2_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-2_CTM	DatasetCapture	2	1		2025-11-03 19:29:45.977975
Proto-2_CTM	LCDatasetCapture	2	1		2025-01-08 16:25:38.820219
Proto-2_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-2_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-2_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-3_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-3_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-3_CTM	DatasetCapture	3	1		2025-11-03 19:29:45.977975
Proto-3_CTM	LCDatasetCapture	3	1		2025-01-08 16:25:38.820219
Proto-3_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-3_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-3_CTM_2	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-3_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-4_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-4_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-4_CTM	DatasetCapture	2	1		2025-11-03 19:29:45.977975
Proto-4_CTM	LCDatasetCapture	2	1		2025-01-08 16:25:38.820219
Proto-4_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-4_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-4_CTM_2	DatasetCapture	2	1		2025-11-03 19:29:45.977975
Proto-4_CTM_2	LCDatasetCapture	2	1		2025-01-08 16:25:38.820219
Proto-4_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-4_CTM_ProcProto-10	ArchiveUpdate	4	0	Runs on Proto-4 but processes data on Proto-10 (temporary fix in February 2016)	2016-02-10 15:30:03
Proto-4_CTM_ProcProto-10	DatasetArchive	3	0	Runs on Proto-4 but processes data on Proto-10	2016-02-10 15:30:04
Proto-4_CTM_ProcProto-7	ArchiveUpdate	4	0	Runs on Proto-4 but processes data on Proto-7 (temporary fix in February 2016)	2016-02-10 15:30:04
Proto-4_CTM_ProcProto-7	DatasetArchive	3	0	Runs on Proto-4 but processes data on Proto-7	2016-02-10 15:30:04
Proto-5_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-5_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-5_CTM	SourceFileRename	4	1		2019-09-10 15:32:16
Proto-5_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-5_CTM_2	DatasetCapture	3	1		2025-11-03 19:29:45.977975
Proto-5_CTM_2	LCDatasetCapture	3	1		2025-01-08 16:25:38.820219
Proto-5_CTM_2	SourceFileRename	4	1		2019-09-10 15:32:15
Proto-6_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-6_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-6_CTM	DatasetCapture	3	1		2025-11-03 19:29:45.977975
Proto-6_CTM	LCDatasetCapture	3	1		2025-01-08 16:25:38.820219
Proto-6_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-6_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-6_CTM_2	DatasetCapture	2	1		2025-11-03 19:29:45.977975
Proto-6_CTM_2	LCDatasetCapture	2	1		2025-01-08 16:25:38.820219
Proto-6_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-7_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-7_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-7_CTM	DatasetCapture	3	1		2025-11-03 19:29:45.977975
Proto-7_CTM	LCDatasetCapture	3	1		2025-01-08 16:25:38.820219
Proto-7_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-7_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-7_CTM_2	DatasetCapture	2	1		2025-11-03 19:29:45.977975
Proto-7_CTM_2	LCDatasetCapture	2	1		2025-01-08 16:25:38.820219
Proto-7_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-8_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-8_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-8_CTM	SourceFileRename	4	1		2019-09-10 15:32:15
Proto-8_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-8_CTM_2	DatasetCapture	3	1	Locked to 15T_FTICR and 12T_FTICR_B via T_Processor_Instrument	2025-11-03 19:29:45.977975
Proto-8_CTM_2	SourceFileRename	4	1	Locked to 15T_FTICR and 12T_FTICR_B via T_Processor_Instrument	2019-09-03 15:03:45
Proto-9_CTM	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-9_CTM	DatasetArchive	3	1		2025-06-17 14:35:09.837903
Proto-9_CTM	SourceFileRename	4	1		2019-07-17 11:33:34
Proto-9_CTM_2	ArchiveUpdate	4	1		2025-06-17 14:35:09.837903
Proto-9_CTM_2	DatasetCapture	3	1		2025-11-03 19:29:45.977975
Proto-9_CTM_2	LCDatasetCapture	3	1		2025-01-08 16:25:38.820219
Proto-9_CTM_2	SourceFileRename	4	1		2019-07-17 11:33:34
Pub-50_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-50_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-50_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-50_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-50_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-50_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-50_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-50_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-50_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-50_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-50_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-51_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-51_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-51_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-51_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-51_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-51_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-51_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-51_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-51_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-51_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-51_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-52_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-52_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-52_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-52_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-52_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-52_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-52_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-52_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-52_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-52_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-52_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-53_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-53_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-53_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-53_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-53_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-53_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-53_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-53_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-53_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-53_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-53_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-54_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-54_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-54_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-54_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-54_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-54_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-54_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-54_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-54_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-54_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-54_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-55_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-55_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-55_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-55_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-55_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-55_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-55_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-55_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-55_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-55_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-55_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-56_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-56_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-56_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-56_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-56_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-56_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-56_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-56_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-56_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-56_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-56_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-57_CTM	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-57_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner	2024-10-18 11:37:50.754207
Pub-57_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-57_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-57_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-57_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data files	2024-02-12 14:21:43
Pub-57_CTM_2	ArchiveStatusCheck	3	1		2025-06-17 14:35:09.837903
Pub-57_CTM_2	ArchiveVerify	3	1		2025-06-17 14:35:09.837903
Pub-57_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in June 2019, limiting each Pub to just one instance of MSFileInfoScanner; re-enabled 2024-09-28	2024-10-18 11:37:50.754207
Pub-57_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-57_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-58_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-58_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-58_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-58_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-58_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-58_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-58_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-58_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-58_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-58_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-58_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-59_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-59_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-59_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-59_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-59_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-59_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-59_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-59_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-59_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-59_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-59_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-60_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-60_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-60_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-60_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-60_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-60_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-60_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-60_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-60_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-60_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-60_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-61_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-61_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-61_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-61_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-61_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-61_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-61_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-61_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-61_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-61_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-61_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-62_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-62_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-62_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-62_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-62_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-62_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-62_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-62_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-62_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-62_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-62_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-63_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-63_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-63_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-63_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-63_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-63_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-63_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-63_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-63_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-63_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-63_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-64_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-64_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-64_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-64_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-64_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-64_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-64_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-64_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-64_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-64_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-64_CTM_2	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-65_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-65_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-65_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-65_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-65_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-65_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-65_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-65_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-65_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-65_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-65_CTM_2	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-66_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-66_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-66_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-66_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-66_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-66_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-66_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-66_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-66_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-66_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-66_CTM_2	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-67_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-67_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-67_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-67_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-67_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-67_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-67_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-67_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-67_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-67_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-67_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-68_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-68_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-68_CTM	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-68_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-68_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-68_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-68_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-68_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-68_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-68_CTM_2	DatasetIntegrity	4	1		2025-07-31 18:08:45.826404
Pub-68_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-69_CTM	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-69_CTM	DatasetInfo	4	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-69_CTM	DatasetIntegrity	4	1	 	2025-09-24 11:37:49.739139
Pub-69_CTM	DatasetQuality	4	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
Pub-69_CTM	ImsDeMultiplex	3	1		2025-01-10 18:37:18.506873
Pub-69_CTM	LCDatasetInfo	4	1	Runs MSFileInfoScanner for LC data filesr; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-69_CTM_2	ArchiveStatusCheck	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-69_CTM_2	ArchiveVerify	3	0	Node on Bionet, no archive access	2025-09-22 17:42:48.417293
Pub-69_CTM_2	DatasetInfo	3	1	Runs MSFileInfoScanner; disabled in September 2025 since Pub-58 thru Pub-93 are now on bionet	2025-10-20 13:16:18.222304
Pub-69_CTM_2	DatasetIntegrity	4	1	 	2025-09-24 11:37:49.739139
Pub-69_CTM_2	DatasetQuality	3	1	Runs Quameter and creates the Metadata.xml file	2024-09-12 18:25:34.085152
\.


--
-- PostgreSQL database dump complete
--

