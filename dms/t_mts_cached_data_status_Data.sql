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
-- Data for Name: t_mts_cached_data_status; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_mts_cached_data_status (table_name, refresh_count, insert_count, update_count, delete_count, last_refreshed, last_refresh_minimum_id, last_full_refresh) FROM stdin;
T_MTS_MT_DB_Jobs_Cached	123648	850036	798386	153825	2024-08-06 12:12:07	2338267	2024-08-05 23:35:54
T_MTS_MT_DBs_Cached	125410	1420	3097	70	2024-08-06 12:12:04	0	2024-08-06 12:12:04
T_MTS_PT_DB_Jobs_Cached	123721	992695	600524	297572	2024-08-06 12:12:05	2297002	2024-08-05 23:35:43
T_MTS_PT_DBs_Cached	125471	405	1867	15	2024-08-06 12:12:04	0	2024-08-06 12:12:04
T_MTS_Peak_Matching_Tasks_Cached	125379	248034	345432	36515	2024-08-06 12:12:04	256621	2024-08-05 23:35:34
\.


--
-- PostgreSQL database dump complete
--

