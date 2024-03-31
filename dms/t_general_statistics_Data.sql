--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
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
1021	RawDataTB	Last 30 days	1	2024-03-28 05:03:49.831035
1006	Campaign_Count	Last 30 days	0.000	2024-03-28 11:03:49.988972
1000	Job_Count	All	2231972.000	2024-03-22 23:03:44.010865
1001	Job_Count	Last 7 days	0.000	2024-03-22 23:03:44.010865
1004	Campaign_Count	All	1966.000	2024-03-22 23:03:44.010865
1005	Campaign_Count	Last 7 days	0.000	2024-03-22 23:03:44.010865
1007	CellCulture_Count	All	18019.000	2024-03-22 23:03:44.010865
1008	CellCulture_Count	Last 7 days	0.000	2024-03-22 23:03:44.010865
1009	CellCulture_Count	Last 30 days	0.000	2024-03-22 23:03:44.010865
1010	Dataset_Count	All	1180037.000	2024-03-22 23:03:44.010865
1011	Dataset_Count	Last 7 days	0.000	2024-03-22 23:03:44.010865
1013	Experiment_Count	All	365665.000	2024-03-22 23:03:44.010865
1014	Experiment_Count	Last 7 days	0.000	2024-03-22 23:03:44.010865
1016	Organism_Count	All	801.000	2024-03-22 23:03:44.010865
1017	Organism_Count	Last 7 days	0.000	2024-03-22 23:03:44.010865
1019	RawDataTB	All	700	2024-03-22 23:03:44.010865
1020	RawDataTB	Last 7 days	0	2024-03-22 23:03:44.010865
1018	Organism_Count	Last 30 days	0.000	2024-03-30 20:03:30.59601
1003	Job_Count	New	5.000	2024-03-30 23:03:30.698584
1015	Experiment_Count	Last 30 days	1.000	2024-03-31 11:03:31.117306
1002	Job_Count	Last 30 days	165.000	2024-03-31 14:03:31.237859
1012	Dataset_Count	Last 30 days	245.000	2024-03-31 14:03:31.237859
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

