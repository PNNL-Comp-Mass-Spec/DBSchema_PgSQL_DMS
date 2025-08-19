--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
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
1000	Job_Count	All	2440538.000	2025-08-18 14:03:14.895889
1001	Job_Count	Last 7 days	467.000	2025-08-18 14:03:14.895889
1002	Job_Count	Last 30 days	9535.000	2025-08-18 14:03:14.895889
1003	Job_Count	New	7.000	2025-08-18 14:03:14.895889
1004	Campaign_Count	All	2137.000	2025-08-15 14:03:11.494806
1005	Campaign_Count	Last 7 days	0.000	2025-08-17 14:03:13.694653
1006	Campaign_Count	Last 30 days	7.000	2025-08-15 20:03:11.869882
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1342770.000	2025-08-18 14:03:14.895889
1011	Dataset_Count	Last 7 days	762.000	2025-08-18 14:03:14.895889
1012	Dataset_Count	Last 30 days	7621.000	2025-08-18 14:03:14.895889
1013	Experiment_Count	All	415186.000	2025-08-18 14:03:14.895889
1014	Experiment_Count	Last 7 days	53.000	2025-08-18 14:03:14.895889
1015	Experiment_Count	Last 30 days	1918.000	2025-08-18 14:03:14.895889
1016	Organism_Count	All	866.000	2025-07-30 20:03:54.751169
1017	Organism_Count	Last 7 days	0.000	2025-08-01 20:03:56.883041
1018	Organism_Count	Last 30 days	20.000	2025-07-30 20:03:54.751169
1019	RawDataTB	All	880	2025-08-13 20:03:09.627326
1020	RawDataTB	Last 7 days	0	2025-08-07 23:04:03.280522
1021	RawDataTB	Last 30 days	14	2025-08-17 23:03:14.384541
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

