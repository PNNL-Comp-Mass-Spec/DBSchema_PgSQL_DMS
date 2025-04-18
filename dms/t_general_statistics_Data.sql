--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
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
1000	Job_Count	All	2388069.000	2025-04-02 14:03:04.253782
1001	Job_Count	Last 7 days	1309.000	2025-04-02 14:03:04.253782
1002	Job_Count	Last 30 days	15196.000	2025-04-02 14:03:04.253782
1003	Job_Count	New	2.000	2025-04-02 14:03:04.253782
1004	Campaign_Count	All	2112.000	2025-03-31 14:04:02.119024
1005	Campaign_Count	Last 7 days	0.000	2025-04-02 14:03:04.253782
1006	Campaign_Count	Last 30 days	10.000	2025-03-31 14:04:02.119024
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1300695.000	2025-04-02 14:03:04.253782
1011	Dataset_Count	Last 7 days	1122.000	2025-04-02 14:03:04.253782
1012	Dataset_Count	Last 30 days	11235.000	2025-04-02 14:03:04.253782
1013	Experiment_Count	All	402390.000	2025-04-02 14:03:04.253782
1014	Experiment_Count	Last 7 days	525.000	2025-04-02 14:03:04.253782
1015	Experiment_Count	Last 30 days	4895.000	2025-04-02 14:03:04.253782
1016	Organism_Count	All	840.000	2025-02-13 23:03:13.483824
1017	Organism_Count	Last 7 days	0.000	2025-02-15 23:03:15.732066
1018	Organism_Count	Last 30 days	0.000	2025-03-15 23:03:45.24107
1019	RawDataTB	All	819	2025-03-29 11:03:59.885415
1020	RawDataTB	Last 7 days	0	2025-03-22 17:03:52.632735
1021	RawDataTB	Last 30 days	7	2025-03-19 23:03:49.783849
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

