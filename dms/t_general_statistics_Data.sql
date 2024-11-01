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
1000	Job_Count	All	2327358.000	2024-10-31 17:03:51.164121
1001	Job_Count	Last 7 days	924.000	2024-10-31 17:03:51.164121
1002	Job_Count	Last 30 days	11479.000	2024-10-31 17:03:51.164121
1003	Job_Count	New	1.000	2024-10-31 17:03:51.164121
1004	Campaign_Count	All	2074.000	2024-10-31 17:03:51.164121
1005	Campaign_Count	Last 7 days	8.000	2024-10-31 17:03:51.164121
1006	Campaign_Count	Last 30 days	45.000	2024-10-31 17:03:51.164121
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1254821.000	2024-10-31 17:03:51.164121
1011	Dataset_Count	Last 7 days	565.000	2024-10-31 17:03:51.164121
1012	Dataset_Count	Last 30 days	8373.000	2024-10-31 17:03:51.164121
1013	Experiment_Count	All	386500.000	2024-10-31 17:03:51.164121
1014	Experiment_Count	Last 7 days	104.000	2024-10-31 14:03:51.03735
1015	Experiment_Count	Last 30 days	2234.000	2024-10-31 17:03:51.164121
1016	Organism_Count	All	831.000	2024-10-29 17:03:49.004098
1017	Organism_Count	Last 7 days	0.000	2024-10-31 17:03:51.164121
1018	Organism_Count	Last 30 days	1.000	2024-10-29 17:03:49.004098
1019	RawDataTB	All	773	2024-10-28 05:03:47.301201
1020	RawDataTB	Last 7 days	0	2024-10-27 14:03:46.746173
1021	RawDataTB	Last 30 days	8	2024-10-30 11:03:49.645036
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

