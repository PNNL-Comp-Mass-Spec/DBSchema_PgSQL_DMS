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
T_MTS_MT_DB_Jobs_Cached	121225	849544	798368	153825	2024-04-22 11:12:04	2292428	2024-04-21 23:35:56
T_MTS_MT_DBs_Cached	122986	1420	3097	70	2024-04-22 11:12:02	0	2024-04-22 11:12:02
T_MTS_Peak_Matching_Tasks_Cached	122957	247936	345335	36515	2024-04-22 11:12:01	256522	2024-04-21 23:35:34
T_MTS_PT_DB_Jobs_Cached	121298	992135	600028	297542	2024-04-22 11:12:02	2233681	2024-04-21 23:35:44
T_MTS_PT_DBs_Cached	123047	405	1867	15	2024-04-22 11:12:02	0	2024-04-22 11:12:02
\.


--
-- PostgreSQL database dump complete
--

