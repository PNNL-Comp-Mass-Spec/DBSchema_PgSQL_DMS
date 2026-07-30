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
1000	Job_Count	All	2552070.000	2026-07-29 14:04:01.310911
1001	Job_Count	Last 7 days	588.000	2026-07-29 14:04:01.310911
1002	Job_Count	Last 30 days	8300.000	2026-07-29 14:04:01.310911
1003	Job_Count	New	6.000	2026-07-29 14:04:01.310911
1004	Campaign_Count	All	2244.000	2026-07-24 14:04:01.289481
1005	Campaign_Count	Last 7 days	0.000	2026-07-26 14:04:01.287233
1006	Campaign_Count	Last 30 days	13.000	2026-07-24 14:04:01.289481
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1439917.000	2026-07-29 14:04:01.310911
1011	Dataset_Count	Last 7 days	832.000	2026-07-29 14:04:01.310911
1012	Dataset_Count	Last 30 days	7839.000	2026-07-29 14:04:01.310911
1013	Experiment_Count	All	456224.000	2026-07-29 14:04:01.310911
1014	Experiment_Count	Last 7 days	671.000	2026-07-29 14:04:01.310911
1015	Experiment_Count	Last 30 days	3505.000	2026-07-29 14:04:01.310911
1016	Organism_Count	All	889.000	2026-07-21 20:04:01.279242
1017	Organism_Count	Last 7 days	0.000	2026-07-23 20:04:01.321937
1018	Organism_Count	Last 30 days	2.000	2026-07-26 20:04:01.283331
1019	RawDataTB	All	1081	2026-07-29 05:04:01.276886
1020	RawDataTB	Last 7 days	0	2026-07-29 14:04:01.310911
1021	RawDataTB	Last 30 days	20	2026-07-29 05:04:01.276886
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

