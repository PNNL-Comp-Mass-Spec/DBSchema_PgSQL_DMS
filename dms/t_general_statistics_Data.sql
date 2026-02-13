--
-- PostgreSQL database dump
--

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

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
1000	Job_Count	All	2508702.000	2026-02-12 20:03:43.130643
1001	Job_Count	Last 7 days	551.000	2026-02-12 20:03:43.130643
1002	Job_Count	Last 30 days	9261.000	2026-02-12 20:03:43.130643
1003	Job_Count	New	2.000	2026-02-12 17:03:43.134908
1004	Campaign_Count	All	2204.000	2026-02-05 20:03:43.151358
1005	Campaign_Count	Last 7 days	0.000	2026-02-07 20:03:43.185818
1006	Campaign_Count	Last 30 days	8.000	2026-02-11 11:03:43.150044
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1402482.000	2026-02-12 20:03:43.130643
1011	Dataset_Count	Last 7 days	362.000	2026-02-12 20:03:43.130643
1012	Dataset_Count	Last 30 days	8977.000	2026-02-12 20:03:43.130643
1013	Experiment_Count	All	429073.000	2026-02-12 11:03:43.155373
1014	Experiment_Count	Last 7 days	97.000	2026-02-12 17:03:43.134908
1015	Experiment_Count	Last 30 days	873.000	2026-02-12 17:03:43.134908
1016	Organism_Count	All	878.000	2026-02-11 17:03:43.135926
1017	Organism_Count	Last 7 days	1.000	2026-02-11 17:03:43.135926
1018	Organism_Count	Last 30 days	3.000	2026-02-11 17:03:43.135926
1019	RawDataTB	All	973	2026-02-11 17:03:43.135926
1020	RawDataTB	Last 7 days	0	2026-02-10 14:03:43.16273
1021	RawDataTB	Last 30 days	16	2026-02-06 20:03:43.126695
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

