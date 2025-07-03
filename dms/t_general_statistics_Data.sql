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
1000	Job_Count	All	2424620.000	2025-07-02 17:03:24.797529
1001	Job_Count	Last 7 days	897.000	2025-07-02 17:03:24.797529
1002	Job_Count	Last 30 days	13156.000	2025-07-02 17:03:24.797529
1003	Job_Count	New	29.000	2025-07-02 17:03:24.797529
1004	Campaign_Count	All	2127.000	2025-07-01 11:03:23.275747
1005	Campaign_Count	Last 7 days	1.000	2025-07-01 11:03:23.275747
1006	Campaign_Count	Last 30 days	4.000	2025-07-01 11:03:23.275747
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1330311.000	2025-07-02 17:03:24.797529
1011	Dataset_Count	Last 7 days	878.000	2025-07-02 17:03:24.797529
1012	Dataset_Count	Last 30 days	10940.000	2025-07-02 17:03:24.797529
1013	Experiment_Count	All	411089.000	2025-07-02 17:03:24.797529
1014	Experiment_Count	Last 7 days	269.000	2025-07-02 17:03:24.797529
1015	Experiment_Count	Last 30 days	3060.000	2025-07-02 17:03:24.797529
1016	Organism_Count	All	846.000	2025-06-11 14:03:55.179899
1017	Organism_Count	Last 7 days	0.000	2025-06-13 14:03:57.356169
1018	Organism_Count	Last 30 days	3.000	2025-06-29 20:03:21.510131
1019	RawDataTB	All	856	2025-07-02 14:03:24.66961
1020	RawDataTB	Last 7 days	1	2025-07-02 14:03:24.66961
1021	RawDataTB	Last 30 days	12	2025-07-02 05:03:24.334403
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

