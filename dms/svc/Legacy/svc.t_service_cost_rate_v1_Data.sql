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
-- Data for Name: t_service_cost_rate; Type: TABLE DATA; Schema: cc; Owner: d3l243
--

COPY cc.t_service_cost_rate (cost_group_id, service_type_id, adjustment, base_rate_per_hour_adj, overhead_hours_per_run, labor_rate_per_hour, labor_hours_per_run) FROM stdin;
100	100	3	158.1	1	200	0.18
100	101	1.4	73.78	1	200	0.18
100	102	2.3	121.21	2	200	0.31
100	103	1.5	79.05	2	200	0.31
100	110	4	210.8	0.1	200	0.012
100	111	1.5	79.05	0.5	200	0.083
100	113	0.9	47.43	0.62	200	0.044
100	104	2	105.4	2	200	0.25
\.


--
-- PostgreSQL database dump complete
--

