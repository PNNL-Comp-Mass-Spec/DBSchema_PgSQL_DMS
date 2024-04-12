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
-- Data for Name: t_misc_paths; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_misc_paths (path_id, path_function, server, client, comment) FROM stdin;
1	AnalysisXfer	na	DMS3_Xfer\\	
3	InstrumentSourceScanDir	G:\\DMS_InstSourceDirScans\\		
4	LCCartConfigDocs		http://gigasax/LC_Cart_Config/	
5	DIMTriggerFileDir	G:\\DIM_Trigger\\	\\\\gigasax\\DIM_Trigger	Deprecated in October 2023 since table T_Dataset_Trigger_File_Create_Queue is now used to track datasets created using the website
6	Database Backup Path	\\\\proto-8\\DB_Backups\\Gigasax_Backup\\	\\\\proto-8\\DB_Backups\\Gigasax_Backup\\	
8	Database Backup Log Path	G:\\SqlServerBackup\\	G:\\SqlServerBackup\\	
9	Redgate Backup Transfer Folder			
10	DMSOrganismFiles	\\\\gigasax\\DMS_Organism_Files\\	F:\\DMS_Organism_Files\\	
11	DMSParameterFiles	\\\\gigasax\\DMS_Parameter_Files\\	F:\\DMS_Parameter_Files\\	The specific folder for each step tool is defined in table T_Analysis_Tool in DMS5 and in table T_Step_Tools in the DMS_Pipeline database
12	Email_alert_admins	EMSL-Prism.Users.DMS_Monitoring_Admins@pnnl.gov	n/a	Used by Post_Email_Alert
13	Spectral_Library_Files	\\\\proto-9\\Spectral_Libraries\\	\\\\proto-9\\Spectral_Libraries\\	Files tracked by T_Spectral_Library
\.


--
-- Name: t_misc_paths_path_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_misc_paths_path_id_seq', 13, true);


--
-- PostgreSQL database dump complete
--

