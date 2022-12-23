--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.1

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
-- Data for Name: t_analysis_job_state; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_analysis_job_state (job_state_id, job_state, comment) FROM stdin;
0	(none)	State is unknown
1	New	New
2	Job In Progress	In progress
3	Results Received	No longer used
4	Complete	Complete
5	Failed	Failed
6	Transfer Failed	No longer used
7	No Intermediate Files Created	Manually used to indicate no results
8	Holding	On hold
9	Transfer In Progress	No longer used
10	Spectra Required	No longer used
11	Spectra Req. In Progress	No longer used
12	Spectra Req. Failed	No longer used
13	Inactive	Job aborted or failed, and we do not plan to re-run this job
14	No Export	Jobs where the data is of no interest; the job completed, but results shouldn't be used elsewhere (including MTS)
15	SpecialClusterFailed	No longer used
16	Data Extraction Required	No longer used
17	Data Extraction In Progress	No longer used
18	Data Extraction Failed	No longer used
19	Special Proc. Waiting	Waiting for jobs that this job depends on to finish
99	Job Broker Failure	No longer used
\.


--
-- PostgreSQL database dump complete
--

