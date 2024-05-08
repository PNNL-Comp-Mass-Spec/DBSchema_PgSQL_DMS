--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
1004	Campaign_Count	All	1984.000	2024-04-22 23:03:29.166312
1005	Campaign_Count	Last 7 days	0.000	2024-04-22 23:03:29.166312
1007	CellCulture_Count	All	18022.000	2024-04-22 23:03:29.166312
1008	CellCulture_Count	Last 7 days	0.000	2024-04-22 23:03:29.166312
1009	CellCulture_Count	Last 30 days	0.000	2024-04-22 23:03:29.166312
1010	Dataset_Count	All	1193119.000	2024-04-22 23:03:29.166312
1013	Experiment_Count	All	369300.000	2024-04-22 23:03:29.166312
1016	Organism_Count	All	823.000	2024-04-22 23:03:29.166312
1017	Organism_Count	Last 7 days	0.000	2024-04-22 23:03:29.166312
1018	Organism_Count	Last 30 days	0.000	2024-04-22 23:03:29.166312
1019	RawDataTB	All	714	2024-04-22 23:03:29.166312
1020	RawDataTB	Last 7 days	0	2024-04-22 23:03:29.166312
1003	Job_Count	New	5.000	2024-04-24 11:03:30.507372
1014	Experiment_Count	Last 7 days	0.000	2024-04-24 11:03:30.507372
1011	Dataset_Count	Last 7 days	0.000	2024-04-24 14:03:30.674754
1002	Job_Count	Last 30 days	4483.000	2024-05-07 17:04:02.320684
1012	Dataset_Count	Last 30 days	3660.000	2024-05-07 17:04:02.320684
1006	Campaign_Count	Last 30 days	6.000	2024-05-04 17:03:41.635986
1021	RawDataTB	Last 30 days	5	2024-05-04 17:03:41.635986
1001	Job_Count	Last 7 days	0.000	2024-04-26 05:03:32.34285
1015	Experiment_Count	Last 30 days	853.000	2024-05-05 17:03:42.630257
1000	Job_Count	All	2249907.000	2024-04-24 05:03:30.212011
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

