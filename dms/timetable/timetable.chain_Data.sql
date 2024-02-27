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
-- Data for Name: chain; Type: TABLE DATA; Schema: timetable; Owner: d3l243
--

COPY timetable.chain (chain_id, chain_name, run_at, max_instances, timeout, live, self_destruct, exclusive_execution, client_name, on_error) FROM stdin;
3	run-vacuum	23 */2 * * *	\N	0	f	f	f	\N	\N
4	clear-log	@reboot	\N	0	t	f	f	\N	\N
\.


--
-- Name: chain_chain_id_seq; Type: SEQUENCE SET; Schema: timetable; Owner: d3l243
--

SELECT pg_catalog.setval('timetable.chain_chain_id_seq', 5, true);


--
-- PostgreSQL database dump complete
--

