--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
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
1000	Job_Count	All	2505794.000	2026-02-03 17:03:50.541607
1001	Job_Count	Last 7 days	568.000	2026-02-03 17:03:50.541607
1002	Job_Count	Last 30 days	8244.000	2026-02-03 17:03:50.541607
1003	Job_Count	New	6.000	2026-02-03 17:03:50.541607
1004	Campaign_Count	All	2203.000	2026-02-02 23:03:50.563962
1005	Campaign_Count	Last 7 days	1.000	2026-02-02 23:03:50.563962
1006	Campaign_Count	Last 30 days	9.000	2026-02-02 23:03:50.563962
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1400587.000	2026-02-03 17:03:50.541607
1011	Dataset_Count	Last 7 days	537.000	2026-02-03 17:03:50.541607
1012	Dataset_Count	Last 30 days	9275.000	2026-02-03 17:03:50.541607
1013	Experiment_Count	All	428779.000	2026-02-03 14:03:50.54107
1014	Experiment_Count	Last 7 days	82.000	2026-02-03 14:03:50.54107
1015	Experiment_Count	Last 30 days	964.000	2026-02-03 14:03:50.54107
1016	Organism_Count	All	877.000	2026-01-14 20:03:50.53307
1017	Organism_Count	Last 7 days	0.000	2026-01-16 20:03:50.57308
1018	Organism_Count	Last 30 days	3.000	2026-01-14 20:03:50.53307
1019	RawDataTB	All	969	2026-01-31 23:03:50.563754
1020	RawDataTB	Last 7 days	0	2026-02-01 20:03:50.591244
1021	RawDataTB	Last 30 days	15	2026-02-01 11:03:50.530493
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

