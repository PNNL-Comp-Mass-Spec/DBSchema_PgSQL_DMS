--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2
-- Dumped by pg_dump version 14.2

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

COPY public.t_requested_run_state_name (state_name, state_id) FROM stdin;
\.


--
-- Name: t_requested_run_state_name_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_requested_run_state_name_state_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

