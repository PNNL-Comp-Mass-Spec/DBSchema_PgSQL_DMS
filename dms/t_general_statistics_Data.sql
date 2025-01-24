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
1000	Job_Count	All	2359162.000	2025-01-23 14:03:50.466929
1001	Job_Count	Last 7 days	706.000	2025-01-23 14:03:50.466929
1002	Job_Count	Last 30 days	10514.000	2025-01-23 14:03:50.466929
1003	Job_Count	New	4.000	2025-01-23 14:03:50.466929
1004	Campaign_Count	All	2094.000	2025-01-20 14:03:47.116734
1005	Campaign_Count	Last 7 days	0.000	2025-01-22 14:03:49.258534
1006	Campaign_Count	Last 30 days	4.000	2025-01-20 14:03:47.116734
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1280032.000	2025-01-23 14:03:50.466929
1011	Dataset_Count	Last 7 days	462.000	2025-01-23 14:03:50.466929
1012	Dataset_Count	Last 30 days	8234.000	2025-01-23 14:03:50.466929
1013	Experiment_Count	All	393332.000	2025-01-23 14:03:50.466929
1014	Experiment_Count	Last 7 days	313.000	2025-01-23 14:03:50.466929
1015	Experiment_Count	Last 30 days	1840.000	2025-01-23 14:03:50.466929
1016	Organism_Count	All	837.000	2025-01-09 20:03:35.843489
1017	Organism_Count	Last 7 days	0.000	2025-01-11 20:03:37.980116
1018	Organism_Count	Last 30 days	3.000	2025-01-16 23:03:43.203263
1019	RawDataTB	All	804	2025-01-21 05:03:48.046581
1020	RawDataTB	Last 7 days	0	2025-01-23 11:03:50.361887
1021	RawDataTB	Last 30 days	10	2025-01-21 05:03:48.046581
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

