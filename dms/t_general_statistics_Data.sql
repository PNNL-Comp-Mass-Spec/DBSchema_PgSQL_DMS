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
1005	Campaign_Count	Last 7 days	0.000	2024-08-15 17:03:28.275857
1000	Job_Count	All	2299160.000	2024-08-22 11:03:35.267247
1021	RawDataTB	Last 30 days	9	2024-08-17 08:03:29.892346
1001	Job_Count	Last 7 days	676.000	2024-08-22 11:03:35.267247
1002	Job_Count	Last 30 days	11059.000	2024-08-22 11:03:35.267247
1003	Job_Count	New	4.000	2024-08-22 11:03:35.267247
1006	Campaign_Count	Last 30 days	9.000	2024-08-19 14:03:32.439344
1010	Dataset_Count	All	1232961.000	2024-08-22 11:03:35.267247
1011	Dataset_Count	Last 7 days	576.000	2024-08-22 11:03:35.267247
1012	Dataset_Count	Last 30 days	8446.000	2024-08-22 11:03:35.267247
1015	Experiment_Count	Last 30 days	4214.000	2024-08-22 11:03:35.267247
1018	Organism_Count	Last 30 days	0.000	2024-08-16 14:03:29.046183
1020	RawDataTB	Last 7 days	0	2024-08-19 17:03:32.554555
1013	Experiment_Count	All	380420.000	2024-08-21 20:03:34.723515
1014	Experiment_Count	Last 7 days	198.000	2024-08-21 20:03:34.723515
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1016	Organism_Count	All	829.000	2024-08-06 17:03:05.868691
1017	Organism_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1004	Campaign_Count	All	2011.000	2024-08-13 17:03:13.283497
1019	RawDataTB	All	752	2024-08-21 05:03:34.256349
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

