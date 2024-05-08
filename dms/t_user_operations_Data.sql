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
-- Data for Name: t_user_operations; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_user_operations (operation_id, operation, operation_description) FROM stdin;
16	DMS_Sample_Preparation	Permissions for sample prep operations
17	DMS_Instrument_Operation	Permissions for MS instrument operators (including all permissions that DMS_Dataset_Operation has).  Configure instruments, LC_Carts, and LC Columns.  Create and disposition datasets.  Update Requested Runs, including Run Assignment.
18	DMS_Infrastructure_Administration	Permissions for most restricted DMS admin operations
19	DMS_Ops_Administration	Permissions for general DMS admin operations
25	DMS_Guest	Can look, but not touch (Note: PNNL network users who are not listed at http://dms2.pnl.gov/user/report automatically get this permission)
26	DMS_User	Permissions for basic operations (Note: Active DMS users at http://dms2.pnl.gov/user/report automatically get this permission, unless they are tagged with DMS_Guest)
32	DMS_Dataset_Operation	Permission to create and disposition datasets, including with Buzzard. Can also update dataset details.
33	DMS_Analysis_Job_Administration	Permission to add/edit analysis jobs
34	DMS_Instrument_Tracking	Permission for instrument usage tracking admin operations, in particular creating placeholder tracking datasets via http://dms2.pnl.gov/tracking_dataset/create
35	DMS_Data_Analysis_Request	Selectable personnel for data analysis requests
36	DMS_Sample_Prep_Request_State	Permission for updating sample prep request states and for updating operations_tasks items (but not listed in the prep request user picklist)
37	DMS_LC_Column_Entry	Permissions to add/update LC columns and Prep LC columns
\.


--
-- Name: t_user_operations_operation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_user_operations_operation_id_seq', 37, true);


--
-- PostgreSQL database dump complete
--

