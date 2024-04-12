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
-- Data for Name: t_task_state_name; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_task_state_name (job_state_id, job_state) FROM stdin;
0	(none)
1	New
2	In Progress
3	Complete
4	Inactive
5	Failed
6	Received
7	Prep. In Progress
8	Preparation Failed
9	Not Ready
10	Restore Required
11	Restore In Progress
12	Restore Failed
14	Failed, Ignore Job Step States
15	Skipped
20	Resuming
100	Hold
101	Ignore
\.


--
-- PostgreSQL database dump complete
--

