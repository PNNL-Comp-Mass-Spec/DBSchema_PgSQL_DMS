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
1000	Job_Count	All	2368710.000	2025-02-17 17:03:17.599309
1001	Job_Count	Last 7 days	794.000	2025-02-17 17:03:17.599309
1002	Job_Count	Last 30 days	11660.000	2025-02-17 17:03:17.599309
1003	Job_Count	New	11.000	2025-02-17 17:03:17.599309
1004	Campaign_Count	All	2101.000	2025-02-14 14:03:14.278657
1005	Campaign_Count	Last 7 days	0.000	2025-02-16 14:03:16.418798
1006	Campaign_Count	Last 30 days	8.000	2025-02-14 14:03:14.278657
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	1999.000	2025-02-10 17:03:10.09347
1010	Dataset_Count	All	1286015.000	2025-02-17 17:03:17.599309
1011	Dataset_Count	Last 7 days	290.000	2025-02-17 14:03:17.392396
1012	Dataset_Count	Last 30 days	7664.000	2025-02-17 17:03:17.599309
1013	Experiment_Count	All	395133.000	2025-02-17 14:03:17.392396
1014	Experiment_Count	Last 7 days	151.000	2025-02-17 14:03:17.392396
1015	Experiment_Count	Last 30 days	2381.000	2025-02-17 14:03:17.392396
1016	Organism_Count	All	840.000	2025-02-13 23:03:13.483824
1017	Organism_Count	Last 7 days	0.000	2025-02-15 23:03:15.732066
1018	Organism_Count	Last 30 days	3.000	2025-02-13 23:03:13.483824
1019	RawDataTB	All	810	2025-02-14 23:03:14.612456
1020	RawDataTB	Last 7 days	0	2025-02-13 05:03:12.726578
1021	RawDataTB	Last 30 days	7	2025-02-08 17:03:07.960232
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

