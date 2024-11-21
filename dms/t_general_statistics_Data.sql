--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

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
1000	Job_Count	All	2336498.000	2024-11-20 20:03:23.237739
1001	Job_Count	Last 7 days	621.000	2024-11-20 20:03:23.237739
1002	Job_Count	Last 30 days	13131.000	2024-11-20 20:03:23.237739
1003	Job_Count	New	3.000	2024-11-20 20:03:23.237739
1004	Campaign_Count	All	2079.000	2024-11-20 17:03:23.162489
1005	Campaign_Count	Last 7 days	1.000	2024-11-20 17:03:23.162489
1006	Campaign_Count	Last 30 days	21.000	2024-11-20 17:03:23.162489
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1262277.000	2024-11-20 20:03:23.237739
1011	Dataset_Count	Last 7 days	613.000	2024-11-20 20:03:23.237739
1012	Dataset_Count	Last 30 days	9791.000	2024-11-20 20:03:23.237739
1013	Experiment_Count	All	387577.000	2024-11-20 17:03:23.162489
1014	Experiment_Count	Last 7 days	313.000	2024-11-20 17:03:23.162489
1015	Experiment_Count	Last 30 days	2234.000	2024-11-20 17:03:23.162489
1016	Organism_Count	All	832.000	2024-11-20 11:03:22.915576
1017	Organism_Count	Last 7 days	1.000	2024-11-20 11:03:22.915576
1018	Organism_Count	Last 30 days	2.000	2024-11-20 11:03:22.915576
1019	RawDataTB	All	779	2024-11-15 14:03:07.385142
1020	RawDataTB	Last 7 days	0	2024-11-14 17:03:06.613857
1021	RawDataTB	Last 30 days	8	2024-11-19 14:03:21.94151
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

