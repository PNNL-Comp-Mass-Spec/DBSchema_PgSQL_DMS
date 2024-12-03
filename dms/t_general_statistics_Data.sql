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
1000	Job_Count	All	2340053.000	2024-12-02 14:03:54.925359
1001	Job_Count	Last 7 days	316.000	2024-12-02 14:03:54.925359
1002	Job_Count	Last 30 days	11962.000	2024-12-02 14:03:54.925359
1003	Job_Count	New	1.000	2024-12-01 23:03:54.382893
1004	Campaign_Count	All	2080.000	2024-11-25 14:03:28.570743
1005	Campaign_Count	Last 7 days	0.000	2024-11-27 14:03:30.719327
1006	Campaign_Count	Last 30 days	5.000	2024-12-01 14:03:54.081119
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1265103.000	2024-12-02 14:03:54.925359
1011	Dataset_Count	Last 7 days	135.000	2024-12-02 14:03:54.925359
1012	Dataset_Count	Last 30 days	9724.000	2024-12-02 14:03:54.925359
1013	Experiment_Count	All	389135.000	2024-12-02 14:03:54.925359
1014	Experiment_Count	Last 7 days	396.000	2024-12-02 14:03:54.925359
1015	Experiment_Count	Last 30 days	2461.000	2024-12-02 14:03:54.925359
1016	Organism_Count	All	832.000	2024-11-20 11:03:22.915576
1017	Organism_Count	Last 7 days	0.000	2024-11-22 11:03:25.067992
1018	Organism_Count	Last 30 days	1.000	2024-11-28 17:03:50.773076
1019	RawDataTB	All	782	2024-11-26 17:03:29.519164
1020	RawDataTB	Last 7 days	0	2024-11-27 17:03:30.827669
1021	RawDataTB	Last 30 days	8	2024-11-30 14:03:52.800174
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

