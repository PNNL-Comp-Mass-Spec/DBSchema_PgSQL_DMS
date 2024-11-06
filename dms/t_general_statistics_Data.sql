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
1000	Job_Count	All	2329200.000	2024-11-05 17:03:56.787519
1001	Job_Count	Last 7 days	826.000	2024-11-05 17:03:56.787519
1002	Job_Count	Last 30 days	10829.000	2024-11-05 17:03:56.787519
1003	Job_Count	New	6.000	2024-11-05 17:03:56.787519
1004	Campaign_Count	All	2075.000	2024-11-01 14:03:52.034972
1005	Campaign_Count	Last 7 days	0.000	2024-11-03 14:03:54.436374
1006	Campaign_Count	Last 30 days	18.000	2024-11-02 20:03:53.390145
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1255985.000	2024-11-05 17:03:56.787519
1011	Dataset_Count	Last 7 days	433.000	2024-11-05 17:03:56.787519
1012	Dataset_Count	Last 30 days	7517.000	2024-11-05 17:03:56.787519
1013	Experiment_Count	All	386734.000	2024-11-05 17:03:56.787519
1014	Experiment_Count	Last 7 days	60.000	2024-11-05 17:03:56.787519
1015	Experiment_Count	Last 30 days	2143.000	2024-11-05 17:03:56.787519
1016	Organism_Count	All	831.000	2024-10-29 17:03:49.004098
1017	Organism_Count	Last 7 days	0.000	2024-10-31 17:03:51.164121
1018	Organism_Count	Last 30 days	1.000	2024-10-29 17:03:49.004098
1019	RawDataTB	All	775	2024-11-05 11:03:56.56701
1020	RawDataTB	Last 7 days	1	2024-11-05 11:03:56.56701
1021	RawDataTB	Last 30 days	8	2024-11-05 11:03:56.56701
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

