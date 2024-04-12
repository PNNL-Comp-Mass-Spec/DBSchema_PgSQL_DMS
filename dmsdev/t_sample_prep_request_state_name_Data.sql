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
-- Data for Name: t_sample_prep_request_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_sample_prep_request_state_name (state_id, state_name, active) FROM stdin;
0	(state used for change tracking)	0
1	New	1
2	On Hold	1
3	Prep in Progress	1
4	Prep Complete	0
5	Closed	1
6	Pending Approval	0
\.


--
-- PostgreSQL database dump complete
--

