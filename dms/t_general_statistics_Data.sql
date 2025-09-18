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
1000	Job_Count	All	2453141.000	2025-09-17 17:03:47.264362
1001	Job_Count	Last 7 days	945.000	2025-09-17 17:03:47.264362
1002	Job_Count	Last 30 days	12301.000	2025-09-17 17:03:47.264362
1003	Job_Count	New	1.000	2025-09-17 17:03:47.264362
1004	Campaign_Count	All	2141.000	2025-09-16 14:03:46.178808
1005	Campaign_Count	Last 7 days	1.000	2025-09-16 14:03:46.178808
1006	Campaign_Count	Last 30 days	4.000	2025-09-16 14:03:46.178808
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1353831.000	2025-09-17 17:03:47.264362
1011	Dataset_Count	Last 7 days	706.000	2025-09-17 17:03:47.264362
1012	Dataset_Count	Last 30 days	10993.000	2025-09-17 17:03:47.264362
1013	Experiment_Count	All	419763.000	2025-09-17 14:03:47.140267
1014	Experiment_Count	Last 7 days	325.000	2025-09-17 17:03:47.264362
1015	Experiment_Count	Last 30 days	4577.000	2025-09-17 14:03:47.140267
1016	Organism_Count	All	867.000	2025-08-26 11:03:23.267531
1017	Organism_Count	Last 7 days	0.000	2025-08-28 11:03:25.43735
1018	Organism_Count	Last 30 days	1.000	2025-08-29 20:03:26.993166
1019	RawDataTB	All	893	2025-09-15 11:03:44.901433
1020	RawDataTB	Last 7 days	0	2025-09-16 20:03:46.525089
1021	RawDataTB	Last 30 days	12	2025-09-17 14:03:47.140267
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

