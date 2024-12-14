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
1000	Job_Count	All	2344907.000	2024-12-13 17:03:06.917458
1001	Job_Count	Last 7 days	888.000	2024-12-13 17:03:06.917458
1002	Job_Count	Last 30 days	12562.000	2024-12-13 17:03:06.917458
1003	Job_Count	New	2.000	2024-12-13 17:03:06.917458
1004	Campaign_Count	All	2090.000	2024-12-12 17:03:06.072021
1005	Campaign_Count	Last 7 days	1.000	2024-12-13 11:03:06.707927
1006	Campaign_Count	Last 30 days	15.000	2024-12-12 17:03:06.072021
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1269039.000	2024-12-13 17:03:06.917458
1011	Dataset_Count	Last 7 days	756.000	2024-12-13 17:03:06.917458
1012	Dataset_Count	Last 30 days	10806.000	2024-12-13 17:03:06.917458
1013	Experiment_Count	All	390570.000	2024-12-13 17:03:06.917458
1014	Experiment_Count	Last 7 days	631.000	2024-12-13 17:03:06.917458
1015	Experiment_Count	Last 30 days	3330.000	2024-12-13 17:03:06.917458
1016	Organism_Count	All	833.000	2024-12-11 23:03:05.037551
1017	Organism_Count	Last 7 days	1.000	2024-12-11 23:03:05.037551
1018	Organism_Count	Last 30 days	2.000	2024-12-11 23:03:05.037551
1019	RawDataTB	All	788	2024-12-12 23:03:06.26928
1020	RawDataTB	Last 7 days	2	2024-12-13 14:03:06.808984
1021	RawDataTB	Last 30 days	10	2024-12-12 20:03:06.189058
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

