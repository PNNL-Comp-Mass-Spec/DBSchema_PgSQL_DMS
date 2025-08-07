--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
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
1000	Job_Count	All	2437097.000	2025-08-06 17:04:02.132894
1001	Job_Count	Last 7 days	464.000	2025-08-06 17:04:02.132894
1002	Job_Count	Last 30 days	10799.000	2025-08-06 17:04:02.132894
1003	Job_Count	New	2.000	2025-08-06 17:04:02.132894
1004	Campaign_Count	All	2135.000	2025-08-05 08:04:00.659669
1005	Campaign_Count	Last 7 days	1.000	2025-08-05 08:04:00.659669
1006	Campaign_Count	Last 30 days	8.000	2025-08-05 08:04:00.659669
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1339625.000	2025-08-06 17:04:02.132894
1011	Dataset_Count	Last 7 days	214.000	2025-08-06 17:04:02.132894
1012	Dataset_Count	Last 30 days	8040.000	2025-08-06 17:04:02.132894
1013	Experiment_Count	All	414409.000	2025-08-06 17:04:02.132894
1014	Experiment_Count	Last 7 days	59.000	2025-08-06 17:04:02.132894
1015	Experiment_Count	Last 30 days	3055.000	2025-08-06 17:04:02.132894
1016	Organism_Count	All	866.000	2025-07-30 20:03:54.751169
1017	Organism_Count	Last 7 days	0.000	2025-08-01 20:03:56.883041
1018	Organism_Count	Last 30 days	20.000	2025-07-30 20:03:54.751169
1019	RawDataTB	All	876	2025-08-06 14:04:01.895045
1020	RawDataTB	Last 7 days	2	2025-08-06 14:04:01.895045
1021	RawDataTB	Last 30 days	16	2025-08-06 14:04:01.895045
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

