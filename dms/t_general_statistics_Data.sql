--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
1001	Job_Count	Last 7 days	0.000	2024-08-03 17:03:28.459162
1011	Dataset_Count	Last 7 days	0.000	2024-08-03 17:03:28.459162
1014	Experiment_Count	Last 7 days	0.000	2024-08-03 17:03:28.459162
1021	RawDataTB	Last 30 days	9	2024-08-04 14:03:29.201321
1002	Job_Count	Last 30 days	11710.000	2024-08-04 17:03:29.29488
1012	Dataset_Count	Last 30 days	8358.000	2024-08-04 17:03:29.29488
1000	Job_Count	All	2291721.000	2024-08-01 20:03:26.392196
1015	Experiment_Count	Last 30 days	2237.000	2024-08-02 20:03:27.278442
1004	Campaign_Count	All	2006.000	2024-08-01 20:03:26.392196
1005	Campaign_Count	Last 7 days	0.000	2024-08-01 20:03:26.392196
1006	Campaign_Count	Last 30 days	7.000	2024-08-01 20:03:26.392196
1007	CellCulture_Count	All	18022.000	2024-08-01 20:03:26.392196
1008	CellCulture_Count	Last 7 days	0.000	2024-08-01 20:03:26.392196
1009	CellCulture_Count	Last 30 days	0.000	2024-08-01 20:03:26.392196
1010	Dataset_Count	All	1226974.000	2024-08-01 20:03:26.392196
1013	Experiment_Count	All	377041.000	2024-08-01 20:03:26.392196
1016	Organism_Count	All	829.000	2024-08-01 20:03:26.392196
1017	Organism_Count	Last 7 days	0.000	2024-08-01 20:03:26.392196
1018	Organism_Count	Last 30 days	2.000	2024-08-01 20:03:26.392196
1019	RawDataTB	All	746	2024-08-01 20:03:26.392196
1020	RawDataTB	Last 7 days	0	2024-08-01 20:03:26.392196
1003	Job_Count	New	23.000	2024-08-02 05:03:26.761022
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

