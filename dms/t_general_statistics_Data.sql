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
1000	Job_Count	All	2465062.000	2025-10-06 17:03:31.908519
1001	Job_Count	Last 7 days	329.000	2025-10-06 17:03:31.908519
1002	Job_Count	Last 30 days	17414.000	2025-10-06 17:03:31.908519
1003	Job_Count	New	16.000	2025-10-06 17:03:31.908519
1004	Campaign_Count	All	2144.000	2025-10-06 11:03:31.938582
1005	Campaign_Count	Last 7 days	1.000	2025-10-06 11:03:31.938582
1006	Campaign_Count	Last 30 days	5.000	2025-10-06 11:03:31.938582
1007	CellCulture_Count	All	20021.000	2025-02-10 17:03:10.09347
1008	CellCulture_Count	Last 7 days	0.000	2025-02-12 17:03:12.24393
1009	CellCulture_Count	Last 30 days	0.000	2025-03-12 17:03:41.916033
1010	Dataset_Count	All	1363461.000	2025-10-06 17:03:31.908519
1011	Dataset_Count	Last 7 days	327.000	2025-10-06 17:03:31.908519
1012	Dataset_Count	Last 30 days	14393.000	2025-10-06 17:03:31.908519
1013	Experiment_Count	All	422573.000	2025-10-06 14:03:31.889422
1014	Experiment_Count	Last 7 days	133.000	2025-10-06 14:03:31.889422
1015	Experiment_Count	Last 30 days	4016.000	2025-10-06 14:03:31.889422
1016	Organism_Count	All	871.000	2025-10-03 20:03:31.894272
1017	Organism_Count	Last 7 days	0.000	2025-10-05 20:03:31.915174
1018	Organism_Count	Last 30 days	4.000	2025-10-03 20:03:31.894272
1019	RawDataTB	All	909	2025-10-02 17:04:02.887966
1020	RawDataTB	Last 7 days	0	2025-10-04 14:03:31.935342
1021	RawDataTB	Last 30 days	20	2025-10-06 05:03:31.881896
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

