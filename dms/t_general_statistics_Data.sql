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
1000	Job_Count	All	2296621.000	2024-08-15 17:03:28.275857
1001	Job_Count	Last 7 days	682.000	2024-08-15 17:03:28.275857
1002	Job_Count	Last 30 days	11958.000	2024-08-15 17:03:28.275857
1003	Job_Count	New	1.000	2024-08-15 17:03:28.275857
1005	Campaign_Count	Last 7 days	0.000	2024-08-15 17:03:28.275857
1010	Dataset_Count	All	1230914.000	2024-08-15 17:03:28.275857
1011	Dataset_Count	Last 7 days	701.000	2024-08-15 17:03:28.275857
1012	Dataset_Count	Last 30 days	9176.000	2024-08-15 17:03:28.275857
1013	Experiment_Count	All	380134.000	2024-08-15 17:03:28.275857
1014	Experiment_Count	Last 7 days	545.000	2024-08-15 17:03:28.275857
1018	Organism_Count	Last 30 days	1.000	2024-08-07 20:03:06.815616
1015	Experiment_Count	Last 30 days	4546.000	2024-08-15 17:03:28.275857
1020	RawDataTB	Last 7 days	0	2024-08-09 14:03:08.709662
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1016	Organism_Count	All	829.000	2024-08-06 17:03:05.868691
1017	Organism_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1004	Campaign_Count	All	2011.000	2024-08-13 17:03:13.283497
1006	Campaign_Count	Last 30 days	12.000	2024-08-13 17:03:13.283497
1019	RawDataTB	All	749	2024-08-15 14:03:28.016978
1021	RawDataTB	Last 30 days	8	2024-08-15 14:03:28.016978
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

