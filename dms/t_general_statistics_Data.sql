--
-- PostgreSQL database dump
--

-- Dumped from database version 18.6
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
1000	Job_Count	All	2575008.000	2026-10-12 14:03:44.460124
1001	Job_Count	Last 7 days	303.000	2026-10-12 14:03:44.460124
1002	Job_Count	Last 30 days	9745.000	2026-10-12 14:03:44.460124
1003	Job_Count	New	4.000	2026-10-12 14:03:44.460124
1004	Campaign_Count	All	2259.000	2026-10-02 14:03:44.48668
1005	Campaign_Count	Last 7 days	0.000	2026-10-04 14:03:44.465987
1006	Campaign_Count	Last 30 days	2.000	2026-10-10 11:03:44.471897
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1462401.000	2026-10-12 14:03:44.460124
1011	Dataset_Count	Last 7 days	212.000	2026-10-12 14:03:44.460124
1012	Dataset_Count	Last 30 days	9766.000	2026-10-12 14:03:44.460124
1013	Experiment_Count	All	462148.000	2026-10-09 17:03:44.496876
1014	Experiment_Count	Last 7 days	0.000	2026-10-11 17:03:44.463938
1015	Experiment_Count	Last 30 days	3054.000	2026-10-11 20:03:44.513588
1016	Organism_Count	All	892.000	2026-09-23 20:03:44.467737
1017	Organism_Count	Last 7 days	0.000	2026-09-25 20:03:44.462673
1018	Organism_Count	Last 30 days	1.000	2026-09-23 20:03:44.467737
1019	RawDataTB	All	1130	2026-10-12 11:03:44.481614
1020	RawDataTB	Last 7 days	0	2026-10-11 05:03:44.469097
1021	RawDataTB	Last 30 days	21	2026-10-12 11:03:44.481614
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

