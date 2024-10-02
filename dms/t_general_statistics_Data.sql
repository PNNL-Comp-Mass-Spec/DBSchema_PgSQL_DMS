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
1000	Job_Count	All	2315489.000	2024-09-30 17:03:17.848595
1001	Job_Count	Last 7 days	666.000	2024-09-30 17:03:17.848595
1002	Job_Count	Last 30 days	11648.000	2024-09-30 17:03:17.848595
1003	Job_Count	New	4.000	2024-09-30 14:03:17.684274
1004	Campaign_Count	All	2029.000	2024-09-25 17:03:12.636727
1005	Campaign_Count	Last 7 days	0.000	2024-09-27 17:03:14.793276
1006	Campaign_Count	Last 30 days	6.000	2024-09-27 17:03:14.793276
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1246325.000	2024-09-30 17:03:17.848595
1011	Dataset_Count	Last 7 days	601.000	2024-09-30 17:03:17.848595
1012	Dataset_Count	Last 30 days	9500.000	2024-09-30 17:03:17.848595
1013	Experiment_Count	All	384214.000	2024-09-30 17:03:17.848595
1014	Experiment_Count	Last 7 days	1.000	2024-09-30 14:03:17.684274
1015	Experiment_Count	Last 30 days	1650.000	2024-09-30 17:03:17.848595
1016	Organism_Count	All	830.000	2024-09-17 23:04:03.98758
1017	Organism_Count	Last 7 days	0.000	2024-09-19 23:03:06.276388
1018	Organism_Count	Last 30 days	1.000	2024-09-17 23:04:03.98758
1019	RawDataTB	All	764	2024-09-29 20:03:17.020289
1020	RawDataTB	Last 7 days	0	2024-09-29 11:03:16.726116
1021	RawDataTB	Last 30 days	10	2024-09-27 23:03:15.001171
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

