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
1000	Job_Count	All	2421828.000	2025-06-25 17:03:17.072999
1001	Job_Count	Last 7 days	1096.000	2025-06-25 17:03:17.072999
1002	Job_Count	Last 30 days	13580.000	2025-06-25 17:03:17.072999
1003	Job_Count	New	1.000	2025-06-25 17:03:17.072999
1004	Campaign_Count	All	2126.000	2025-06-18 11:03:09.175815
1005	Campaign_Count	Last 7 days	0.000	2025-06-20 11:03:11.295491
1006	Campaign_Count	Last 30 days	6.000	2025-06-20 14:03:11.432383
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1328095.000	2025-06-25 17:03:17.072999
1011	Dataset_Count	Last 7 days	676.000	2025-06-25 17:03:17.072999
1012	Dataset_Count	Last 30 days	11633.000	2025-06-25 17:03:17.072999
1013	Experiment_Count	All	410667.000	2025-06-25 17:03:17.072999
1014	Experiment_Count	Last 7 days	274.000	2025-06-25 17:03:17.072999
1015	Experiment_Count	Last 30 days	3495.000	2025-06-25 17:03:17.072999
1016	Organism_Count	All	846.000	2025-06-11 14:03:55.179899
1017	Organism_Count	Last 7 days	0.000	2025-06-13 14:03:57.356169
1018	Organism_Count	Last 30 days	5.000	2025-06-11 14:03:55.179899
1019	RawDataTB	All	851	2025-06-23 23:03:15.150434
1020	RawDataTB	Last 7 days	1	2025-06-23 23:03:15.150434
1021	RawDataTB	Last 30 days	10	2025-06-24 23:03:16.418672
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

