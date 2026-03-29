--
-- PostgreSQL database dump
--

-- Dumped from database version 18.3
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
1000	Job_Count	All	2519538.000	2026-03-28 17:03:16.279593
1001	Job_Count	Last 7 days	725.000	2026-03-28 17:03:16.279593
1002	Job_Count	Last 30 days	7823.000	2026-03-28 17:03:16.279593
1003	Job_Count	New	3.000	2026-03-28 17:03:16.279593
1004	Campaign_Count	All	2216.000	2026-03-27 11:03:16.264876
1005	Campaign_Count	Last 7 days	2.000	2026-03-28 11:03:16.284686
1006	Campaign_Count	Last 30 days	6.000	2026-03-27 11:03:16.264876
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1412403.000	2026-03-28 17:03:16.279593
1011	Dataset_Count	Last 7 days	1277.000	2026-03-28 17:03:16.279593
1012	Dataset_Count	Last 30 days	6943.000	2026-03-28 17:03:16.279593
1013	Experiment_Count	All	446187.000	2026-03-27 17:03:16.32406
1014	Experiment_Count	Last 7 days	62.000	2026-03-28 17:03:16.279593
1015	Experiment_Count	Last 30 days	2553.000	2026-03-28 11:03:16.284686
1016	Organism_Count	All	879.000	2026-03-11 14:03:43.16458
1017	Organism_Count	Last 7 days	0.000	2026-03-13 14:03:43.159567
1018	Organism_Count	Last 30 days	1.000	2026-03-13 17:03:43.154718
1019	RawDataTB	All	992	2026-03-28 08:03:16.257954
1020	RawDataTB	Last 7 days	2	2026-03-28 05:03:16.251696
1021	RawDataTB	Last 30 days	12	2026-03-28 08:03:16.257954
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

