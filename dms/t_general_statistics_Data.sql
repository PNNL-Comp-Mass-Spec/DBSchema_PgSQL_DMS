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
1000	Job_Count	All	2463545.000	2025-10-01 17:04:01.762483
1001	Job_Count	Last 7 days	1484.000	2025-10-01 17:04:01.762483
1002	Job_Count	Last 30 days	17779.000	2025-10-01 17:04:01.762483
1003	Job_Count	New	1.000	2025-10-01 17:04:01.762483
1004	Campaign_Count	All	2143.000	2025-09-30 17:04:00.788352
1005	Campaign_Count	Last 7 days	1.000	2025-09-30 17:04:00.788352
1006	Campaign_Count	Last 30 days	4.000	2025-09-30 17:04:00.788352
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1362452.000	2025-10-01 17:04:01.762483
1011	Dataset_Count	Last 7 days	1391.000	2025-10-01 17:04:01.762483
1012	Dataset_Count	Last 30 days	15287.000	2025-10-01 17:04:01.762483
1013	Experiment_Count	All	422425.000	2025-10-01 14:04:01.577615
1014	Experiment_Count	Last 7 days	1065.000	2025-10-01 17:04:01.762483
1015	Experiment_Count	Last 30 days	5364.000	2025-10-01 14:04:01.577615
1016	Organism_Count	All	869.000	2025-10-01 11:04:01.476439
1017	Organism_Count	Last 7 days	1.000	2025-10-01 11:04:01.476439
1018	Organism_Count	Last 30 days	2.000	2025-10-01 11:04:01.476439
1019	RawDataTB	All	908	2025-09-30 17:04:00.788352
1020	RawDataTB	Last 7 days	2	2025-10-01 17:04:01.762483
1021	RawDataTB	Last 30 days	22	2025-09-30 17:04:00.788352
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

