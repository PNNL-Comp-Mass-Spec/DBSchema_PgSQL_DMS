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
-- Data for Name: t_mts_cached_data_status; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_mts_cached_data_status (table_name, refresh_count, insert_count, update_count, delete_count, last_refreshed, last_refresh_minimum_id, last_full_refresh) FROM stdin;
T_MTS_MT_DB_Jobs_Cached	120135	849338	798350	153825	2024-03-02 15:35:55	-2147483647	2024-03-02 15:35:55
T_MTS_MT_DBs_Cached	121896	1420	3097	70	2024-03-02 15:35:35	0	2024-03-02 15:35:35
T_MTS_Peak_Matching_Tasks_Cached	121871	247872	345247	36515	2024-03-02 15:35:35	-2147483647	2024-03-02 15:35:35
T_MTS_PT_DB_Jobs_Cached	120208	992135	600028	297542	2024-03-02 15:35:44	-2147483647	2024-03-02 15:35:44
T_MTS_PT_DBs_Cached	121957	405	1867	15	2024-03-02 15:35:35	0	2024-03-02 15:35:35
\.


--
-- PostgreSQL database dump complete
--

