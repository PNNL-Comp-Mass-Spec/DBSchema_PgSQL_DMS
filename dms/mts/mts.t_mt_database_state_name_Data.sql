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
-- Data for Name: t_mt_database_state_name; Type: TABLE DATA; Schema: mts; Owner: d3l243
--

COPY mts.t_mt_database_state_name (state_id, state_name) FROM stdin;
0	(na)
1	Development
2	Production
3	Frozen
4	Holding
5	Pre-Production
7	Scheduled to be frozen
10	Unused
15	Moved to alternate server
90	Scheduled to be deleted
100	Deleted
\.


--
-- PostgreSQL database dump complete
--

