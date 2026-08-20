--
-- PostgreSQL database dump
--

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.3

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
1000	Job_Count	All	2557684.000	2026-08-19 14:04:01.302475
1001	Job_Count	Last 7 days	845.000	2026-08-19 14:04:01.302475
1002	Job_Count	Last 30 days	9210.000	2026-08-19 14:04:01.302475
1003	Job_Count	New	2.000	2026-08-19 08:04:01.27429
1004	Campaign_Count	All	2254.000	2026-08-06 08:04:01.282943
1005	Campaign_Count	Last 7 days	0.000	2026-08-08 08:04:01.284094
1006	Campaign_Count	Last 30 days	15.000	2026-08-13 17:04:01.300397
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1444453.000	2026-08-19 14:04:01.302475
1011	Dataset_Count	Last 7 days	688.000	2026-08-19 14:04:01.302475
1012	Dataset_Count	Last 30 days	8390.000	2026-08-19 14:04:01.302475
1013	Experiment_Count	All	457719.000	2026-08-18 17:04:01.304315
1014	Experiment_Count	Last 7 days	30.000	2026-08-19 14:04:01.302475
1015	Experiment_Count	Last 30 days	2873.000	2026-08-19 14:04:01.302475
1016	Organism_Count	All	891.000	2026-08-12 20:04:01.301076
1017	Organism_Count	Last 7 days	0.000	2026-08-14 20:04:01.290538
1018	Organism_Count	Last 30 days	3.000	2026-08-12 20:04:01.301076
1019	RawDataTB	All	1095	2026-08-13 17:04:01.300397
1020	RawDataTB	Last 7 days	1	2026-08-18 23:04:01.303536
1021	RawDataTB	Last 30 days	21	2026-08-18 23:04:01.303536
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

