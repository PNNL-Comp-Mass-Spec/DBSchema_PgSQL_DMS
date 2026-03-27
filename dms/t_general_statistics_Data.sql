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
1000	Job_Count	All	2518906.000	2026-03-26 20:03:16.277497
1001	Job_Count	Last 7 days	858.000	2026-03-26 20:03:16.277497
1002	Job_Count	Last 30 days	7431.000	2026-03-26 20:03:16.277497
1003	Job_Count	New	3.000	2026-03-26 14:03:16.305059
1004	Campaign_Count	All	2214.000	2026-03-26 11:03:16.296963
1005	Campaign_Count	Last 7 days	1.000	2026-03-26 11:03:16.296963
1006	Campaign_Count	Last 30 days	4.000	2026-03-26 11:03:16.296963
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1411258.000	2026-03-26 20:03:16.277497
1011	Dataset_Count	Last 7 days	706.000	2026-03-26 20:03:16.277497
1012	Dataset_Count	Last 30 days	5971.000	2026-03-26 20:03:16.277497
1013	Experiment_Count	All	446126.000	2026-03-26 20:03:16.277497
1014	Experiment_Count	Last 7 days	128.000	2026-03-26 20:03:16.277497
1015	Experiment_Count	Last 30 days	3010.000	2026-03-26 20:03:16.277497
1016	Organism_Count	All	879.000	2026-03-11 14:03:43.16458
1017	Organism_Count	Last 7 days	0.000	2026-03-13 14:03:43.159567
1018	Organism_Count	Last 30 days	1.000	2026-03-13 17:03:43.154718
1019	RawDataTB	All	990	2026-03-25 14:03:53.947442
1020	RawDataTB	Last 7 days	1	2026-03-25 08:03:53.902658
1021	RawDataTB	Last 30 days	11	2026-03-25 11:03:53.915781
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

