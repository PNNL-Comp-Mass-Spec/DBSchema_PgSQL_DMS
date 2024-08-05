--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
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
-- Data for Name: t_mts_cached_data_status; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_mts_cached_data_status (table_name, refresh_count, insert_count, update_count, delete_count, last_refreshed, last_refresh_minimum_id, last_full_refresh) FROM stdin;
T_MTS_MT_DB_Jobs_Cached	123533	849955	798383	153825	2024-08-01 15:12:03	2335616	2024-07-31 23:35:54
T_MTS_MT_DBs_Cached	125295	1420	3097	70	2024-08-01 15:12:01	0	2024-08-01 15:12:01
T_MTS_Peak_Matching_Tasks_Cached	125264	248013	345414	36515	2024-08-01 15:12:01	256600	2024-07-31 23:35:34
T_MTS_PT_DB_Jobs_Cached	123606	992695	600524	297572	2024-08-01 15:12:02	2297002	2024-07-31 23:35:42
T_MTS_PT_DBs_Cached	125356	405	1867	15	2024-08-01 15:12:01	0	2024-08-01 15:12:01
\.


--
-- PostgreSQL database dump complete
--

