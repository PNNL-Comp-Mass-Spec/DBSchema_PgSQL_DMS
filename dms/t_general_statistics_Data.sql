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
1000	Job_Count	All	2508015.000	2026-02-09 20:03:43.152807
1001	Job_Count	Last 7 days	667.000	2026-02-09 20:03:43.152807
1002	Job_Count	Last 30 days	9003.000	2026-02-09 20:03:43.152807
1003	Job_Count	New	3.000	2026-02-09 20:03:43.152807
1004	Campaign_Count	All	2204.000	2026-02-05 20:03:43.151358
1005	Campaign_Count	Last 7 days	0.000	2026-02-07 20:03:43.185818
1006	Campaign_Count	Last 30 days	9.000	2026-02-08 14:03:43.124642
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1402014.000	2026-02-09 20:03:43.152807
1011	Dataset_Count	Last 7 days	447.000	2026-02-09 20:03:43.152807
1012	Dataset_Count	Last 30 days	9285.000	2026-02-09 20:03:43.152807
1013	Experiment_Count	All	428884.000	2026-02-09 14:03:43.156843
1014	Experiment_Count	Last 7 days	30.000	2026-02-09 14:03:43.156843
1015	Experiment_Count	Last 30 days	696.000	2026-02-09 14:03:43.156843
1016	Organism_Count	All	877.000	2026-01-14 20:03:50.53307
1017	Organism_Count	Last 7 days	0.000	2026-01-16 20:03:50.57308
1018	Organism_Count	Last 30 days	2.000	2026-02-06 20:03:43.126695
1019	RawDataTB	All	972	2026-02-07 23:03:43.128005
1020	RawDataTB	Last 7 days	0	2026-02-09 05:03:43.159144
1021	RawDataTB	Last 30 days	16	2026-02-06 20:03:43.126695
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

