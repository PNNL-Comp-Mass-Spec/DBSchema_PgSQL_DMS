--
-- PostgreSQL database dump
--

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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
-- Data for Name: t_service_cost_group; Type: TABLE DATA; Schema: svc; Owner: d3l243
--

COPY svc.t_service_cost_group (cost_group_id, description, service_cost_state_id, entered) FROM stdin;
100	Initial group	3	2025-06-18 19:29:08.807107
101	FY26	3	2025-08-07 15:20:48.677057
102	FY26, June revision	2	2026-04-09 15:58:58.530306
\.


--
-- Name: t_service_cost_group_cost_group_id_seq; Type: SEQUENCE SET; Schema: svc; Owner: d3l243
--

SELECT pg_catalog.setval('svc.t_service_cost_group_cost_group_id_seq', 102, true);


--
-- PostgreSQL database dump complete
--

