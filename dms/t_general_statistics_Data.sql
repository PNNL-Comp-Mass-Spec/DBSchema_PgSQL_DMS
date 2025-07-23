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
1000	Job_Count	All	2432493.000	2025-07-22 17:03:46.4476
1001	Job_Count	Last 7 days	1198.000	2025-07-22 17:03:46.4476
1002	Job_Count	Last 30 days	12216.000	2025-07-22 17:03:46.4476
1003	Job_Count	New	3.000	2025-07-22 17:03:46.4476
1004	Campaign_Count	All	2132.000	2025-07-21 17:03:45.202722
1005	Campaign_Count	Last 7 days	2.000	2025-07-21 17:03:45.202722
1006	Campaign_Count	Last 30 days	6.000	2025-07-21 17:03:45.202722
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1336409.000	2025-07-22 17:03:46.4476
1011	Dataset_Count	Last 7 days	1067.000	2025-07-22 17:03:46.4476
1012	Dataset_Count	Last 30 days	9477.000	2025-07-22 17:03:46.4476
1013	Experiment_Count	All	413877.000	2025-07-21 17:03:45.202722
1014	Experiment_Count	Last 7 days	182.000	2025-07-21 20:03:45.282574
1015	Experiment_Count	Last 30 days	3772.000	2025-07-21 23:03:45.422868
1016	Organism_Count	All	846.000	2025-06-11 14:03:55.179899
1017	Organism_Count	Last 7 days	0.000	2025-06-13 14:03:57.356169
1018	Organism_Count	Last 30 days	0.000	2025-07-11 14:03:34.479795
1019	RawDataTB	All	867	2025-07-22 05:03:45.660683
1020	RawDataTB	Last 7 days	1	2025-07-22 05:03:45.660683
1021	RawDataTB	Last 30 days	17	2025-07-22 05:03:45.660683
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

