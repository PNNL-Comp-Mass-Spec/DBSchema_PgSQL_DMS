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
-- Data for Name: t_scripts; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_scripts (script_id, script, description, enabled, results_tag, contents) FROM stdin;
1	DatasetCapture	This script is for basic dataset capture	Y	CAP	<JobScript Name="DatasetCapture"><Step Number="1" Tool="DatasetCapture" /><Step Number="2" Tool="DatasetIntegrity"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="DatasetInfo"><Depends_On Step_Number="2" /></Step><Step Number="4" Tool="DatasetQuality"><Depends_On Step_Number="3" /></Step></JobScript>
2	ArchiveUpdate	This script pushes a dataset into MyEMSL, optionally pushing a specific results directory below the dataset	Y	UPD	<JobScript Name="ArchiveUpdate"><Step Number="1" Tool="ArchiveUpdate" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ArchiveStatusCheck"><Depends_On Step_Number="2" /></Step></JobScript>
3	DatasetArchive	This script is for initial archive of dataset	Y	DSA	<JobScript Name="DatasetArchive"><Step Number="1" Tool="DatasetArchive" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step></JobScript>
4	SourceFileRename	This script is for renaming the source file or folder on the instrument	Y	SFR	<JobScript Name="SourceFileRename"><Step Number="1" Tool="SourceFileRename" /></JobScript>
5	HPLCSequenceCapture	This script is for capture of HPLC sequence files	N	CAP	<JobScript Name="HPLCSequenceCapture"><Step Number="1" Tool="DatasetCapture" /></JobScript>
6	IMSDatasetCapture	This script is for IMS dataset capture	Y	CPI	<JobScript Name="IMSDatasetCapture"><Step Number="1" Tool="DatasetCapture" /><Step Number="2" Tool="DatasetIntegrity"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ImsDeMultiplex"><Depends_On Step_Number="2" /></Step><Step Number="4" Tool="DatasetInfo"><Depends_On Step_Number="2" /><Depends_On Step_Number="3" /></Step><Step Number="5" Tool="DatasetQuality"><Depends_On Step_Number="4" /></Step></JobScript>
7	IMSDemultiplex	This script is for re-running the Demultiplexing tool on IMS datasets	Y	DMX	<JobScript Name="IMSDemultiplex"><Step Number="1" Tool="ImsDeMultiplex" /></JobScript>
8	Quameter	This script is for running the Quameter tool on datasets	Y	QUA	<JobScript Name="Quameter"><Step Number="1" Tool="DatasetQuality" /></JobScript>
9	MyEMSLDatasetPush	This script pushes a dataset into MyEMSL, it does not push in subfolders; disabled in 2023 since ArchiveUpdate always uses MyEMSL	N	PSH	<JobScript Name="MyEMSLDatasetPush"><Step Number="1" Tool="ArchiveUpdate" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ArchiveStatusCheck"><Depends_On Step_Number="2" /></Step></JobScript>
10	MyEMSLDatasetPushRecursive	This script pushes a dataset, plus all of its subfolders, into MyEMSL; disabled in 2023 since ArchiveUpdate always uses MyEMSL	N	PSH	<JobScript Name="MyEMSLDatasetPushRecursive"><Step Number="1" Tool="ArchiveUpdate" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ArchiveStatusCheck"><Depends_On Step_Number="2" /></Step></JobScript>
12	MyEMSLVerify	This script runs the ArchiveStatusCheck tool to make sure that MyEMSL has validated the checksums of ingested data, including making sure it has been copied to tape.	Y	DSV	<JobScript Name="MyEMSLVerify"><Step Number="1" Tool="ArchiveStatusCheck" /></JobScript>
13	LCDatasetCapture	This script is for LC data capture	Y	LCD	<JobScript Name="LCDatasetCapture"><Step Number="1" Tool="LCDatasetCapture"/><Step Number="2" Tool="DatasetIntegrity"><Depends_On Step_Number="1" Test="Target_Skipped"/></Step><Step Number="3" Tool="LCDatasetInfo"><Depends_On Step_Number="2" Test="Target_Skipped"/></Step></JobScript>
\.


--
-- Name: t_scripts_script_id_seq; Type: SEQUENCE SET; Schema: cap; Owner: d3l243
--

SELECT pg_catalog.setval('cap.t_scripts_script_id_seq', 13, true);


--
-- PostgreSQL database dump complete
--

