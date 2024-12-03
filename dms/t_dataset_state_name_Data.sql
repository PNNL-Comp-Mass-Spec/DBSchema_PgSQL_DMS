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
-- Data for Name: t_dataset_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_state_name (dataset_state_id, dataset_state) FROM stdin;
1	New
2	Capture In Progress
3	Complete
4	Inactive
5	Capture Failed
6	Received
7	Prep. In Progress
8	Preparation Failed
9	Not Ready
10	Restore Required
11	Restore In Progress
12	Restore Failed
13	Holding
14	Capture Failed, Duplicate Dataset Files
\.


--
-- PostgreSQL database dump complete
--

