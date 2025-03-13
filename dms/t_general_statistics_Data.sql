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
1000	Job_Count	All	2378032.000	2025-03-13 14:03:42.719931
1001	Job_Count	Last 7 days	2028.000	2025-03-13 14:03:42.719931
1002	Job_Count	Last 30 days	11774.000	2025-03-13 14:03:42.719931
1003	Job_Count	New	29.000	2025-03-13 14:03:42.719931
1004	Campaign_Count	All	2105.000	2025-03-11 17:03:40.656513
1005	Campaign_Count	Last 7 days	1.000	2025-03-11 17:03:40.656513
1006	Campaign_Count	Last 30 days	5.000	2025-03-11 17:03:40.656513
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1293068.000	2025-03-13 14:03:42.719931
1011	Dataset_Count	Last 7 days	1550.000	2025-03-13 14:03:42.719931
1012	Dataset_Count	Last 30 days	8257.000	2025-03-13 14:03:42.719931
1013	Experiment_Count	All	399664.000	2025-03-13 14:03:42.719931
1014	Experiment_Count	Last 7 days	240.000	2025-03-13 14:03:42.719931
1015	Experiment_Count	Last 30 days	5391.000	2025-03-13 14:03:42.719931
1016	Organism_Count	All	840.000	2025-02-13 23:03:13.483824
1017	Organism_Count	Last 7 days	0.000	2025-02-15 23:03:15.732066
1018	Organism_Count	Last 30 days	1.000	2025-02-23 14:03:24.099817
1019	RawDataTB	All	814	2025-03-10 17:03:39.718284
1020	RawDataTB	Last 7 days	0	2025-03-13 08:03:42.464267
1021	RawDataTB	Last 30 days	6	2025-03-10 23:03:40.009884
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

