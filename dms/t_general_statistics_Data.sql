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
1000	Job_Count	All	2303664.000	2024-08-30 20:03:44.585054
1001	Job_Count	Last 7 days	1141.000	2024-08-30 20:03:44.585054
1002	Job_Count	Last 30 days	12375.000	2024-08-30 20:03:44.585054
1003	Job_Count	New	4.000	2024-08-30 20:03:44.585054
1004	Campaign_Count	All	2023.000	2024-08-28 17:03:42.080222
1005	Campaign_Count	Last 7 days	0.000	2024-08-30 17:03:44.326904
1006	Campaign_Count	Last 30 days	17.000	2024-08-29 08:03:42.887231
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1236895.000	2024-08-30 20:03:44.585054
1011	Dataset_Count	Last 7 days	1120.000	2024-08-30 20:03:44.585054
1012	Dataset_Count	Last 30 days	10136.000	2024-08-30 20:03:44.585054
1013	Experiment_Count	All	382564.000	2024-08-30 14:03:44.125304
1014	Experiment_Count	Last 7 days	27.000	2024-08-30 14:03:44.125304
1015	Experiment_Count	Last 30 days	5536.000	2024-08-30 17:03:44.326904
1016	Organism_Count	All	829.000	2024-08-06 17:03:05.868691
1017	Organism_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1018	Organism_Count	Last 30 days	0.000	2024-08-16 14:03:29.046183
1019	RawDataTB	All	754	2024-08-30 20:03:44.585054
1020	RawDataTB	Last 7 days	0	2024-08-19 17:03:32.554555
1021	RawDataTB	Last 30 days	8	2024-08-29 05:03:42.740118
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

