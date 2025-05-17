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
1000	Job_Count	All	2404283.000	2025-05-16 20:03:51.581268
1001	Job_Count	Last 7 days	1137.000	2025-05-16 20:03:51.581268
1002	Job_Count	Last 30 days	11977.000	2025-05-16 20:03:51.581268
1003	Job_Count	New	2.000	2025-05-16 20:03:51.581268
1004	Campaign_Count	All	2118.000	2025-05-16 17:03:51.493551
1005	Campaign_Count	Last 7 days	1.000	2025-05-16 17:03:51.493551
1006	Campaign_Count	Last 30 days	5.000	2025-05-16 17:03:51.493551
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1313121.000	2025-05-16 20:03:51.581268
1011	Dataset_Count	Last 7 days	1071.000	2025-05-16 20:03:51.581268
1012	Dataset_Count	Last 30 days	9146.000	2025-05-16 20:03:51.581268
1013	Experiment_Count	All	406624.000	2025-05-16 17:03:51.493551
1014	Experiment_Count	Last 7 days	933.000	2025-05-16 17:03:51.493551
1015	Experiment_Count	Last 30 days	2662.000	2025-05-16 17:03:51.493551
1016	Organism_Count	All	841.000	2025-04-08 17:03:10.81782
1017	Organism_Count	Last 7 days	0.000	2025-04-10 17:03:13.114609
1018	Organism_Count	Last 30 days	0.000	2025-05-08 17:03:42.838896
1019	RawDataTB	All	836	2025-05-16 05:03:50.859284
1020	RawDataTB	Last 7 days	1	2025-05-13 20:03:48.376219
1021	RawDataTB	Last 30 days	9	2025-05-16 17:03:51.493551
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

