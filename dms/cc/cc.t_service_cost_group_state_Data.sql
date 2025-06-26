--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
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
-- Data for Name: t_service_cost_group_state; Type: TABLE DATA; Schema: cc; Owner: d3l243
--

COPY cc.t_service_cost_group_state (service_cost_state_id, service_cost_state) FROM stdin;
1	New
2	Active
3	Inactive
\.


--
-- Name: t_service_cost_group_state_service_cost_state_id_seq; Type: SEQUENCE SET; Schema: cc; Owner: d3l243
--

SELECT pg_catalog.setval('cc.t_service_cost_group_state_service_cost_state_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

