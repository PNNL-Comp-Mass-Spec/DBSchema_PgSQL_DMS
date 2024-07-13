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
-- Data for Name: t_step_tools; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_step_tools (step_tool_id, step_tool, description, bionet_required, only_on_storage_server, instrument_capacity_limited, holdoff_interval_minutes, number_of_retries, processor_assignment_applies) FROM stdin;
1	DatasetCapture	Create dataset folder on storage server and copy instrument data into it	Y	N	Y	0	0	Y
2	DatasetArchive	Create dataset folder on archive and copy everything from storage dataset folder into it	N	Y	N	60	1	N
3	ArchiveUpdate	Create specific analysis results folder in dataset folder in archive and copy contents of results folder in storage to it	N	Y	N	60	4	N
4	DatasetInfo	Create QC graphics using MSFileInfoScanner	N	N	N	0	0	N
5	SourceFileRename	Put "x_" prefix on source files or source folders in the instrument source directory	Y	N	N	120	75	N
8	DatasetIntegrity	Makes sure that captured file is valid (not too small, required files/folders are present). For Agilent GC, converts the .D folder to CDF using OpenChrom.	N	N	N	0	0	N
9	DatasetQuality	Creates the metadata.xml file and runs Quameter	N	N	N	0	0	N
10	ImsDeMultiplex	Demultiplexes data in a .uimf files if acquired as multiplexed data. For Agilent IMS data acquired natively as a .D directory, demultiplexes (if necessary) to create a new .D directory. Next, convert to either a .uimf file or a .mza file.	N	N	N	5	4	N
11	ArchiveUpdateTest	Test instance of the ArchiveUpdate tool	N	Y	N	1	10	N
12	ArchiveVerify	Verify that checksums reported by MyEMSL match those of the ingested data (using https://metadata.my.emsl.pnl.gov/fileinfo/files_for_keyvalue/omics.dms.dataset_id/598409)	N	N	N	10	90	N
13	ArchiveStatusCheck	Verify that all of the ingest jobs associated with the given dataset are complete (look for task_percent = 100 at https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1300940)	N	N	N	20	90	N
14	LCDatasetCapture	Copy LC instrument data into dataset LC subfolder on storage server	Y	N	Y	30	48	Y
15	LCDatasetInfo	Create QC graphics using MSFileInfoScanner, but do not overwrite the MS dataset info	N	N	N	0	0	N
\.


--
-- Name: t_step_tools_step_tool_id_seq; Type: SEQUENCE SET; Schema: cap; Owner: d3l243
--

SELECT pg_catalog.setval('cap.t_step_tools_step_tool_id_seq', 15, true);


--
-- PostgreSQL database dump complete
--

