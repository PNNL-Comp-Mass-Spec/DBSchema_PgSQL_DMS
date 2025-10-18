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
1000	Job_Count	All	2470771.000	2025-10-17 17:03:31.894152
1001	Job_Count	Last 7 days	1892.000	2025-10-17 17:03:31.894152
1002	Job_Count	Last 30 days	17631.000	2025-10-17 17:03:31.894152
1003	Job_Count	New	3.000	2025-10-17 17:03:31.894152
1004	Campaign_Count	All	2152.000	2025-10-17 17:03:31.894152
1005	Campaign_Count	Last 7 days	1.000	2025-10-17 17:03:31.894152
1006	Campaign_Count	Last 30 days	11.000	2025-10-17 17:03:31.894152
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1367390.000	2025-10-17 17:03:31.894152
1011	Dataset_Count	Last 7 days	796.000	2025-10-17 17:03:31.894152
1012	Dataset_Count	Last 30 days	13559.000	2025-10-17 17:03:31.894152
1013	Experiment_Count	All	422891.000	2025-10-17 17:03:31.894152
1014	Experiment_Count	Last 7 days	86.000	2025-10-17 14:03:31.894291
1015	Experiment_Count	Last 30 days	3128.000	2025-10-17 17:03:31.894152
1016	Organism_Count	All	871.000	2025-10-03 20:03:31.894272
1017	Organism_Count	Last 7 days	0.000	2025-10-05 20:03:31.915174
1018	Organism_Count	Last 30 days	4.000	2025-10-03 20:03:31.894272
1019	RawDataTB	All	912	2025-10-16 23:03:31.926936
1020	RawDataTB	Last 7 days	0	2025-10-17 14:03:31.894291
1021	RawDataTB	Last 30 days	19	2025-10-16 11:03:31.939305
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

