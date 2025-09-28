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
1000	Job_Count	All	2461045.000	2025-09-27 17:03:57.466611
1001	Job_Count	Last 7 days	1383.000	2025-09-27 17:03:57.466611
1002	Job_Count	Last 30 days	16767.000	2025-09-27 17:03:57.466611
1003	Job_Count	New	1.000	2025-09-27 17:03:57.466611
1004	Campaign_Count	All	2142.000	2025-09-23 11:03:53.400986
1005	Campaign_Count	Last 7 days	0.000	2025-09-25 11:03:55.071367
1006	Campaign_Count	Last 30 days	3.000	2025-09-27 17:03:57.466611
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1360464.000	2025-09-27 17:03:57.466611
1011	Dataset_Count	Last 7 days	1083.000	2025-09-27 17:03:57.466611
1012	Dataset_Count	Last 30 days	14454.000	2025-09-27 17:03:57.466611
1013	Experiment_Count	All	421140.000	2025-09-26 17:03:56.60115
1014	Experiment_Count	Last 7 days	44.000	2025-09-27 17:03:57.466611
1015	Experiment_Count	Last 30 days	4539.000	2025-09-27 17:03:57.466611
1016	Organism_Count	All	868.000	2025-09-26 20:03:56.7161
1017	Organism_Count	Last 7 days	1.000	2025-09-26 20:03:56.7161
1018	Organism_Count	Last 30 days	1.000	2025-09-26 20:03:56.7161
1019	RawDataTB	All	901	2025-09-27 17:03:57.466611
1020	RawDataTB	Last 7 days	1	2025-09-26 17:03:56.60115
1021	RawDataTB	Last 30 days	16	2025-09-27 08:03:57.105288
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

