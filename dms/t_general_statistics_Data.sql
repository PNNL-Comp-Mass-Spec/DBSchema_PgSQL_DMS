--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
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
-- Data for Name: t_general_statistics; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_general_statistics (entry_id, category, label, value, last_affected) FROM stdin;
1000	Job_Count	All	2353000.000	2025-01-08 14:03:34.814972
1001	Job_Count	Last 7 days	860.000	2025-01-08 14:03:34.814972
1002	Job_Count	Last 30 days	9935.000	2025-01-08 14:03:34.814972
1003	Job_Count	New	5.000	2025-01-08 14:03:34.814972
1004	Campaign_Count	All	2092.000	2025-01-03 11:03:29.248231
1005	Campaign_Count	Last 7 days	0.000	2025-01-05 11:03:31.471113
1006	Campaign_Count	Last 30 days	4.000	2025-01-08 14:03:34.814972
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1275077.000	2025-01-08 14:03:34.814972
1011	Dataset_Count	Last 7 days	478.000	2025-01-08 14:03:34.814972
1012	Dataset_Count	Last 30 days	7586.000	2025-01-08 14:03:34.814972
1013	Experiment_Count	All	391603.000	2025-01-08 14:03:34.814972
1014	Experiment_Count	Last 7 days	48.000	2025-01-08 14:03:34.814972
1015	Experiment_Count	Last 30 days	1893.000	2025-01-08 14:03:34.814972
1016	Organism_Count	All	834.000	2024-12-17 23:03:11.622552
1017	Organism_Count	Last 7 days	0.000	2024-12-19 23:03:13.877467
1018	Organism_Count	Last 30 days	2.000	2024-12-20 11:03:14.387814
1019	RawDataTB	All	800	2025-01-06 08:03:32.514124
1020	RawDataTB	Last 7 days	0	2025-01-08 05:03:34.512681
1021	RawDataTB	Last 30 days	15	2025-01-06 08:03:32.514124
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

