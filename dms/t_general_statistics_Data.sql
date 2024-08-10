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
-- Data for Name: t_general_statistics; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_general_statistics (entry_id, category, label, value, last_affected) FROM stdin;
1018	Organism_Count	Last 30 days	1.000	2024-08-07 20:03:06.815616
1020	RawDataTB	Last 7 days	0	2024-08-09 14:03:08.709662
1013	Experiment_Count	All	379153.000	2024-08-09 17:03:08.851181
1015	Experiment_Count	Last 30 days	4196.000	2024-08-09 17:03:08.851181
1000	Job_Count	All	2294785.000	2024-08-09 20:03:08.984617
1001	Job_Count	Last 7 days	561.000	2024-08-09 20:03:08.984617
1002	Job_Count	Last 30 days	13275.000	2024-08-09 20:03:08.984617
1003	Job_Count	New	1.000	2024-08-09 20:03:08.984617
1004	Campaign_Count	All	2010.000	2024-08-09 20:03:08.984617
1005	Campaign_Count	Last 7 days	3.000	2024-08-09 20:03:08.984617
1006	Campaign_Count	Last 30 days	11.000	2024-08-09 20:03:08.984617
1019	RawDataTB	All	748	2024-08-08 23:03:08.17413
1010	Dataset_Count	All	1229238.000	2024-08-09 20:03:08.984617
1011	Dataset_Count	Last 7 days	632.000	2024-08-09 20:03:08.984617
1012	Dataset_Count	Last 30 days	9535.000	2024-08-09 20:03:08.984617
1014	Experiment_Count	Last 7 days	570.000	2024-08-09 20:03:08.984617
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1016	Organism_Count	All	829.000	2024-08-06 17:03:05.868691
1017	Organism_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1021	RawDataTB	Last 30 days	10	2024-08-06 17:03:05.868691
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

