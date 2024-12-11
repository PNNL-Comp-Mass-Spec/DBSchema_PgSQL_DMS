--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
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
1000	Job_Count	All	2343605.000	2024-12-10 20:03:04.074611
1001	Job_Count	Last 7 days	788.000	2024-12-10 20:03:04.074611
1002	Job_Count	Last 30 days	11925.000	2024-12-10 20:03:04.074611
1003	Job_Count	New	3.000	2024-12-10 17:04:03.932452
1004	Campaign_Count	All	2088.000	2024-12-09 14:04:02.618988
1005	Campaign_Count	Last 7 days	5.000	2024-12-09 14:04:02.618988
1006	Campaign_Count	Last 30 days	13.000	2024-12-09 14:04:02.618988
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1267803.000	2024-12-10 20:03:04.074611
1011	Dataset_Count	Last 7 days	428.000	2024-12-10 20:03:04.074611
1012	Dataset_Count	Last 30 days	9962.000	2024-12-10 20:03:04.074611
1013	Experiment_Count	All	389900.000	2024-12-10 17:04:03.932452
1014	Experiment_Count	Last 7 days	194.000	2024-12-10 17:04:03.932452
1015	Experiment_Count	Last 30 days	2997.000	2024-12-10 17:04:03.932452
1016	Organism_Count	All	832.000	2024-11-20 11:03:22.915576
1017	Organism_Count	Last 7 days	0.000	2024-11-22 11:03:25.067992
1018	Organism_Count	Last 30 days	1.000	2024-11-28 17:03:50.773076
1019	RawDataTB	All	786	2024-12-10 14:04:03.744962
1020	RawDataTB	Last 7 days	0	2024-12-08 14:04:01.44333
1021	RawDataTB	Last 30 days	8	2024-12-08 14:04:01.44333
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

