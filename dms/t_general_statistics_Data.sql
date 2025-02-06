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
1000	Job_Count	All	2364269.000	2025-02-05 17:03:04.600494
1001	Job_Count	Last 7 days	1066.000	2025-02-05 17:03:04.600494
1002	Job_Count	Last 30 days	12094.000	2025-02-05 17:03:04.600494
1003	Job_Count	New	5.000	2025-02-05 17:03:04.600494
1004	Campaign_Count	All	2100.000	2025-01-31 14:03:58.960966
1005	Campaign_Count	Last 7 days	0.000	2025-02-02 14:04:01.144774
1006	Campaign_Count	Last 30 days	8.000	2025-02-02 11:04:00.997192
1007	CellCulture_Count	All	18022.000	2025-01-23 20:03:50.650695
1008	CellCulture_Count	Last 7 days	0.000	2025-01-23 20:03:50.650695
1009	CellCulture_Count	Last 30 days	0.000	2025-01-23 20:03:50.650695
1010	Dataset_Count	All	1283176.000	2025-02-05 17:03:04.600494
1011	Dataset_Count	Last 7 days	461.000	2025-02-05 17:03:04.600494
1012	Dataset_Count	Last 30 days	8550.000	2025-02-05 17:03:04.600494
1013	Experiment_Count	All	394202.000	2025-02-05 17:03:04.600494
1014	Experiment_Count	Last 7 days	47.000	2025-02-05 17:03:04.600494
1015	Experiment_Count	Last 30 days	2647.000	2025-02-05 17:03:04.600494
1016	Organism_Count	All	839.000	2025-01-24 14:03:51.430169
1017	Organism_Count	Last 7 days	0.000	2025-01-26 14:03:53.758743
1018	Organism_Count	Last 30 days	5.000	2025-01-24 14:03:51.430169
1019	RawDataTB	All	808	2025-02-05 17:03:04.600494
1020	RawDataTB	Last 7 days	0	2025-02-02 14:04:01.144774
1021	RawDataTB	Last 30 days	8	2025-02-04 17:04:03.481934
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

