--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

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
-- Data for Name: t_job_state_name; Type: TABLE DATA; Schema: sw; Owner: d3l243
--

COPY sw.t_job_state_name (job_state_id, job_state) FROM stdin;
0	(none)
1	New
2	Job In Progress
3	Results Received
4	Complete
5	Failed
6	Transfer Failed
7	No Intermediate Files Created
8	Holding
9	Transfer In Progress
10	Spectra Required
11	Spectra Req. In Progress
12	Spectra Req. Failed
13	Inactive
14	No Export
15	SpecialClusterFailed
16	Data Extraction Required
17	Data Extraction In Progress
18	Data Extraction Failed
20	Resuming
21	Permanent
\.


--
-- PostgreSQL database dump complete
--

