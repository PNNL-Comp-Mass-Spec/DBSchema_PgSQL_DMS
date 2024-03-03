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
-- Data for Name: t_requested_run_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_requested_run_state_name (state_id, state_name) FROM stdin;
1	Active
2	Completed
5	Fractionated
4	Holding
3	Inactive
\.


--
-- Name: t_requested_run_state_name_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_requested_run_state_name_state_id_seq', 5, true);


--
-- PostgreSQL database dump complete
--

