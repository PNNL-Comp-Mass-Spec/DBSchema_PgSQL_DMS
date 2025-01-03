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
1000	Job_Count	All	2351216.000	2025-01-02 17:03:28.560536
1001	Job_Count	Last 7 days	483.000	2025-01-02 17:03:28.560536
1002	Job_Count	Last 30 days	10606.000	2025-01-02 17:03:28.560536
1003	Job_Count	New	3.000	2025-01-02 14:03:28.493838
1004	Campaign_Count	All	2091.000	2025-01-02 17:03:28.560536
1005	Campaign_Count	Last 7 days	1.000	2025-01-02 17:03:28.560536
1006	Campaign_Count	Last 30 days	10.000	2025-01-02 17:03:28.560536
1007	CellCulture_Count	All	18022.000	2024-08-06 17:03:05.868691
1008	CellCulture_Count	Last 7 days	0.000	2024-08-06 17:03:05.868691
1009	CellCulture_Count	Last 30 days	0.000	2024-08-06 17:03:05.868691
1010	Dataset_Count	All	1273796.000	2025-01-02 17:03:28.560536
1011	Dataset_Count	Last 7 days	269.000	2025-01-02 17:03:28.560536
1012	Dataset_Count	Last 30 days	8195.000	2025-01-02 17:03:28.560536
1013	Experiment_Count	All	391535.000	2025-01-02 17:03:28.560536
1014	Experiment_Count	Last 7 days	24.000	2025-01-02 17:03:28.560536
1015	Experiment_Count	Last 30 days	2360.000	2025-01-02 17:03:28.560536
1016	Organism_Count	All	834.000	2024-12-17 23:03:11.622552
1017	Organism_Count	Last 7 days	0.000	2024-12-19 23:03:13.877467
1018	Organism_Count	Last 30 days	2.000	2024-12-20 11:03:14.387814
1019	RawDataTB	All	797	2025-01-01 20:03:27.639057
1020	RawDataTB	Last 7 days	1	2025-01-02 08:03:28.245312
1021	RawDataTB	Last 30 days	15	2025-01-01 20:03:27.639057
\.


--
-- Name: t_general_statistics_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_general_statistics_entry_id_seq', 1021, true);


--
-- PostgreSQL database dump complete
--

