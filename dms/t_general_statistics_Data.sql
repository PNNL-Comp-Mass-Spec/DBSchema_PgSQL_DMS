--
-- PostgreSQL database dump
--

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.3

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
1000	Job_Count	All	2548976.000	2026-07-21 17:04:01.292739
1001	Job_Count	Last 7 days	652.000	2026-07-21 14:04:01.281734
1002	Job_Count	Last 30 days	7478.000	2026-07-21 17:04:01.292739
1003	Job_Count	New	9.000	2026-07-21 17:04:01.292739
1004	Campaign_Count	All	2240.000	2026-07-20 23:04:01.34035
1005	Campaign_Count	Last 7 days	1.000	2026-07-20 23:04:01.34035
1006	Campaign_Count	Last 30 days	10.000	2026-07-20 23:04:01.34035
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1436546.000	2026-07-21 17:04:01.292739
1011	Dataset_Count	Last 7 days	510.000	2026-07-21 17:04:01.292739
1012	Dataset_Count	Last 30 days	6394.000	2026-07-21 14:04:01.281734
1013	Experiment_Count	All	454975.000	2026-07-21 14:04:01.281734
1014	Experiment_Count	Last 7 days	210.000	2026-07-21 14:04:01.281734
1015	Experiment_Count	Last 30 days	3326.000	2026-07-21 14:04:01.281734
1016	Organism_Count	All	888.000	2026-07-10 11:04:01.341812
1017	Organism_Count	Last 7 days	0.000	2026-07-12 11:04:01.281102
1018	Organism_Count	Last 30 days	7.000	2026-07-10 11:04:01.341812
1019	RawDataTB	All	1075	2026-07-17 17:04:01.304388
1020	RawDataTB	Last 7 days	0	2026-07-16 20:04:01.303146
1021	RawDataTB	Last 30 days	25	2026-07-19 20:04:01.307983
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

