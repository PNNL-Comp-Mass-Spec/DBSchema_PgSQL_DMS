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

COPY cc.t_service_cost_rate (cost_group_id, service_type_id, indirect_per_run, direct_per_run, non_labor_per_run) FROM stdin;
100	100	0	36	158.1
100	101	0	36	73.78
100	102	0	62	242.42
100	103	0	62	158.1
100	104	0	50	210.8
100	110	0	2.4	21.08
100	111	0	16.6	39.525
100	112	0	16.6	39.525
100	113	0	8.8	29.4066
101	100	52.63	60.61	26.74
101	101	52.63	27.22	25
101	102	52.63	87.26	79.87
101	103	52.63	82.44	24.79
101	104	52.63	59.37	87.72
101	110	5.03	8.52	4
101	111	5.03	28.94	5.95
101	112	5.03	14.87	3.06
101	113	5.03	17.7	5.77
\.


--
-- PostgreSQL database dump complete
--

