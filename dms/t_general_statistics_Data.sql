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
1000	Job_Count	All	2367102.000	2025-02-13 20:03:13.303755
1001	Job_Count	Last 7 days	748.000	2025-02-13 20:03:13.303755
1002	Job_Count	Last 30 days	11481.000	2025-02-13 20:03:13.303755
1003	Job_Count	New	4.000	2025-02-13 20:03:13.303755
1004	Campaign_Count	All	2100.000	2025-01-31 14:03:58.960966
1005	Campaign_Count	Last 7 days	0.000	2025-02-02 14:04:01.144774
1006	Campaign_Count	Last 30 days	7.000	2025-02-12 14:03:12.151435
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	1999.000	2025-02-10 17:03:10.09347
1010	Dataset_Count	All	1285367.000	2025-02-13 20:03:13.303755
1011	Dataset_Count	Last 7 days	512.000	2025-02-13 20:03:13.303755
1012	Dataset_Count	Last 30 days	8194.000	2025-02-13 20:03:13.303755
1013	Experiment_Count	All	394326.000	2025-02-13 20:03:13.303755
1014	Experiment_Count	Last 7 days	37.000	2025-02-13 20:03:13.303755
1015	Experiment_Count	Last 30 days	1889.000	2025-02-13 20:03:13.303755
1016	Organism_Count	All	839.000	2025-01-24 14:03:51.430169
1017	Organism_Count	Last 7 days	0.000	2025-01-26 14:03:53.758743
1018	Organism_Count	Last 30 days	2.000	2025-02-08 20:03:08.08169
1019	RawDataTB	All	809	2025-02-10 23:03:10.308385
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

