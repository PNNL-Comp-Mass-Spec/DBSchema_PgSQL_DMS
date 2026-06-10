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
1000	Job_Count	All	2539574.000	2026-06-09 17:03:05.360856
1001	Job_Count	Last 7 days	520.000	2026-06-09 14:03:30.807936
1002	Job_Count	Last 30 days	7358.000	2026-06-09 17:03:05.360856
1003	Job_Count	New	2.000	2026-06-09 17:03:05.360856
1004	Campaign_Count	All	2228.000	2026-05-20 17:03:30.828982
1005	Campaign_Count	Last 7 days	0.000	2026-05-22 17:03:30.801151
1006	Campaign_Count	Last 30 days	3.000	2026-06-05 14:03:30.772908
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1427411.000	2026-06-09 17:03:05.360856
1011	Dataset_Count	Last 7 days	477.000	2026-06-09 17:03:05.360856
1012	Dataset_Count	Last 30 days	6001.000	2026-06-09 17:03:05.360856
1013	Experiment_Count	All	450314.000	2026-06-09 14:03:30.807936
1014	Experiment_Count	Last 7 days	74.000	2026-06-09 14:03:30.807936
1015	Experiment_Count	Last 30 days	1621.000	2026-06-09 14:03:30.807936
1016	Organism_Count	All	881.000	2026-06-01 17:03:30.828056
1017	Organism_Count	Last 7 days	0.000	2026-06-03 17:03:30.802651
1018	Organism_Count	Last 30 days	1.000	2026-06-01 17:03:30.828056
1019	RawDataTB	All	1041	2026-06-08 08:03:30.798724
1020	RawDataTB	Last 7 days	1	2026-06-09 05:03:30.815141
1021	RawDataTB	Last 30 days	16	2026-06-09 11:03:30.800524
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

