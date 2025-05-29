--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
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
1000	Job_Count	All	2408858.000	2025-05-28 14:03:04.259898
1001	Job_Count	Last 7 days	614.000	2025-05-28 14:03:04.259898
1002	Job_Count	Last 30 days	12699.000	2025-05-28 14:03:04.259898
1003	Job_Count	New	4.000	2025-05-28 14:03:04.259898
1004	Campaign_Count	All	2121.000	2025-05-27 17:04:03.521214
1005	Campaign_Count	Last 7 days	1.000	2025-05-27 17:04:03.521214
1006	Campaign_Count	Last 30 days	5.000	2025-05-27 17:04:03.521214
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1317282.000	2025-05-28 14:03:04.259898
1011	Dataset_Count	Last 7 days	822.000	2025-05-28 14:03:04.259898
1012	Dataset_Count	Last 30 days	10911.000	2025-05-28 14:03:04.259898
1013	Experiment_Count	All	407224.000	2025-05-28 11:03:04.149453
1014	Experiment_Count	Last 7 days	52.000	2025-05-28 11:03:04.149453
1015	Experiment_Count	Last 30 days	2213.000	2025-05-28 14:03:04.259898
1016	Organism_Count	All	842.000	2025-05-27 14:04:03.369137
1017	Organism_Count	Last 7 days	1.000	2025-05-27 14:04:03.369137
1018	Organism_Count	Last 30 days	1.000	2025-05-27 14:04:03.369137
1019	RawDataTB	All	842	2025-05-27 11:04:03.131656
1020	RawDataTB	Last 7 days	1	2025-05-27 23:04:03.714943
1021	RawDataTB	Last 30 days	11	2025-05-27 23:04:03.714943
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

