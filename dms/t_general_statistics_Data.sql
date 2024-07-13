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
1001	Job_Count	Last 7 days	3.000	2024-07-11 17:03:19.002976
1011	Dataset_Count	Last 7 days	0.000	2024-07-11 17:03:19.002976
1002	Job_Count	Last 30 days	12213.000	2024-07-12 20:03:20.413801
1012	Dataset_Count	Last 30 days	10020.000	2024-07-12 20:03:20.413801
1015	Experiment_Count	Last 30 days	2059.000	2024-07-12 20:03:20.413801
1017	Organism_Count	Last 7 days	0.000	2024-07-10 20:03:18.239403
1021	RawDataTB	Last 30 days	8	2024-07-10 23:03:18.376873
1000	Job_Count	All	2280907.000	2024-07-11 05:03:18.595914
1003	Job_Count	New	4.000	2024-07-11 05:03:18.595914
1014	Experiment_Count	Last 7 days	0.000	2024-07-11 14:03:18.874706
1004	Campaign_Count	All	1999.000	2024-07-09 23:03:17.062791
1005	Campaign_Count	Last 7 days	0.000	2024-07-09 23:03:17.062791
1006	Campaign_Count	Last 30 days	3.000	2024-07-09 23:03:17.062791
1007	CellCulture_Count	All	18022.000	2024-07-09 23:03:17.062791
1008	CellCulture_Count	Last 7 days	0.000	2024-07-09 23:03:17.062791
1009	CellCulture_Count	Last 30 days	0.000	2024-07-09 23:03:17.062791
1010	Dataset_Count	All	1219327.000	2024-07-09 23:03:17.062791
1013	Experiment_Count	All	374897.000	2024-07-09 23:03:17.062791
1016	Organism_Count	All	828.000	2024-07-09 23:03:17.062791
1018	Organism_Count	Last 30 days	2.000	2024-07-09 23:03:17.062791
1019	RawDataTB	All	737	2024-07-09 23:03:17.062791
1020	RawDataTB	Last 7 days	0	2024-07-09 23:03:17.062791
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

