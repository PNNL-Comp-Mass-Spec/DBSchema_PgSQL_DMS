--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
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
1000	Job_Count	All	2498139.000	2026-01-07 17:03:50.540292
1001	Job_Count	Last 7 days	519.000	2026-01-07 17:03:50.540292
1002	Job_Count	Last 30 days	7716.000	2026-01-07 17:03:50.540292
1003	Job_Count	New	2.000	2026-01-07 17:03:50.540292
1004	Campaign_Count	All	2194.000	2025-12-19 11:03:50.54156
1005	Campaign_Count	Last 7 days	0.000	2025-12-21 11:03:50.549709
1006	Campaign_Count	Last 30 days	3.000	2026-01-07 17:03:50.540292
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1391749.000	2026-01-07 17:03:50.540292
1011	Dataset_Count	Last 7 days	387.000	2026-01-07 17:03:50.540292
1012	Dataset_Count	Last 30 days	7631.000	2026-01-07 17:03:50.540292
1013	Experiment_Count	All	427993.000	2026-01-06 20:03:50.538339
1014	Experiment_Count	Last 7 days	167.000	2026-01-07 17:03:50.540292
1015	Experiment_Count	Last 30 days	1116.000	2026-01-07 17:03:50.540292
1016	Organism_Count	All	874.000	2025-11-18 23:03:50.564478
1017	Organism_Count	Last 7 days	0.000	2025-11-20 23:03:50.535255
1018	Organism_Count	Last 30 days	0.000	2025-12-18 23:03:50.53352
1019	RawDataTB	All	955	2026-01-05 08:03:50.583542
1020	RawDataTB	Last 7 days	1	2026-01-07 08:03:50.553351
1021	RawDataTB	Last 30 days	12	2026-01-07 11:03:50.559307
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

