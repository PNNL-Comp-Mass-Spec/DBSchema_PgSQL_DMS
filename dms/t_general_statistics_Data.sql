--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

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
-- Data for Name: t_general_statistics; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_general_statistics (entry_id, category, label, value, last_affected) FROM stdin;
1000	Job_Count	All	2326434.000	2024-10-29 17:03:49.004098
1001	Job_Count	Last 7 days	1186.000	2024-10-29 17:03:49.004098
1002	Job_Count	Last 30 days	11540.000	2024-10-29 17:03:49.004098
1003	Job_Count	New	2.000	2024-10-29 17:03:49.004098
1004	Campaign_Count	All	2066.000	2024-10-24 14:03:43.351071
1005	Campaign_Count	Last 7 days	0.000	2024-10-26 14:03:45.457764
1006	Campaign_Count	Last 30 days	37.000	2024-10-25 17:03:44.711343
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1254256.000	2024-10-29 17:03:49.004098
1011	Dataset_Count	Last 7 days	671.000	2024-10-29 17:03:49.004098
1012	Dataset_Count	Last 30 days	8487.000	2024-10-29 17:03:49.004098
1013	Experiment_Count	All	386396.000	2024-10-29 17:03:49.004098
1014	Experiment_Count	Last 7 days	116.000	2024-10-29 17:03:49.004098
1015	Experiment_Count	Last 30 days	2183.000	2024-10-29 17:03:49.004098
1016	Organism_Count	All	831.000	2024-10-29 17:03:49.004098
1017	Organism_Count	Last 7 days	1.000	2024-10-29 17:03:49.004098
1018	Organism_Count	Last 30 days	1.000	2024-10-29 17:03:49.004098
1019	RawDataTB	All	773	2024-10-28 05:03:47.301201
1020	RawDataTB	Last 7 days	0	2024-10-27 14:03:46.746173
1021	RawDataTB	Last 30 days	9	2024-10-27 11:03:46.667027
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

