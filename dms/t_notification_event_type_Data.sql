--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
-- Dumped by pg_dump version 16.1

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
-- Data for Name: t_notification_event_type; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_notification_event_type (event_type_id, event_type, target_entity_type, link_template, visible) FROM stdin;
1	Requested Run Batch Start	1	requested_run_batch/show/@ID@	Y
2	Requested Run Batch Finish	1	requested_run_batch/show/@ID@	Y
3	Requested Run Batch Acq Time Ready	1	\N	N
4	Analysis Job Request Start	2	analysis_job_request/show/@ID@	N
5	Analysis Job Request Finish	2	analysis_job_request/show/@ID@	Y
11	Sample Prep Req (New)	3	sample_prep_request/show/@ID@	Y
12	Sample Prep Req (Open)	3	sample_prep_request/show/@ID@	Y
13	Sample Prep Req (Prep in Progress)	3	sample_prep_request/show/@ID@	Y
14	Sample Prep Req (Prep Complete)	3	sample_prep_request/show/@ID@	Y
15	Sample Prep Req (Closed)	3	sample_prep_request/show/@ID@	Y
16	Sample Prep Req (Pending Approval)	3	sample_prep_request/show/@ID@	Y
20	Dataset Not Released	4	dataset/report/-/@ID@	Y
21	Dataset Released	5	dataset/report/-/@ID@	Y
\.


--
-- PostgreSQL database dump complete
--

