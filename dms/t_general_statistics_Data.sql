--
-- PostgreSQL database dump
--

-- Dumped from database version 18.6
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
1000	Job_Count	All	2577697.000	2026-10-21 17:04:03.347514
1001	Job_Count	Last 7 days	1126.000	2026-10-21 17:04:03.347514
1002	Job_Count	Last 30 days	10156.000	2026-10-21 17:04:03.347514
1003	Job_Count	New	62.000	2026-10-21 17:04:03.347514
1004	Campaign_Count	All	2261.000	2026-10-20 17:03:44.481786
1005	Campaign_Count	Last 7 days	1.000	2026-10-21 14:04:03.353538
1006	Campaign_Count	Last 30 days	3.000	2026-10-20 17:03:44.481786
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1464964.000	2026-10-21 17:04:03.347514
1011	Dataset_Count	Last 7 days	1389.000	2026-10-21 17:04:03.347514
1012	Dataset_Count	Last 30 days	9974.000	2026-10-21 17:04:03.347514
1013	Experiment_Count	All	462499.000	2026-10-21 14:04:03.353538
1014	Experiment_Count	Last 7 days	66.000	2026-10-21 17:04:03.347514
1015	Experiment_Count	Last 30 days	2869.000	2026-10-21 14:04:03.353538
1016	Organism_Count	All	893.000	2026-10-15 20:03:44.493152
1017	Organism_Count	Last 7 days	0.000	2026-10-17 20:03:44.494898
1018	Organism_Count	Last 30 days	2.000	2026-10-15 20:03:44.493152
1019	RawDataTB	All	1137	2026-10-20 14:03:44.474148
1020	RawDataTB	Last 7 days	1	2026-10-21 11:03:44.482936
1021	RawDataTB	Last 30 days	21	2026-10-20 05:03:44.501592
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

