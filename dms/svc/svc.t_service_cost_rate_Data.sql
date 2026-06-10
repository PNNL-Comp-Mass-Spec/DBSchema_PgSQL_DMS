--
-- PostgreSQL database dump
--

-- Dumped from database version 18.4
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
-- Data for Name: t_service_cost_rate; Type: TABLE DATA; Schema: svc; Owner: d3l243
--

COPY svc.t_service_cost_rate (cost_group_id, service_type_id, indirect_per_run, direct_per_run, non_labor_per_run, doe_burdened_rate_per_run, hhs_burdened_rate_per_run, ldrd_burdened_rate_per_run) FROM stdin;
101	100	49.18	59.23	26.74	184.64	195.1	136.37
101	101	49.18	26.6	25	137.69	145.49	101.69
101	102	49.18	85.3	79.87	292.84	309.43	216.28
101	103	49.18	80.55	24.79	211.1	223.06	155.91
101	104	49.18	23.18	35.09	146.8	155.11	108.42
101	110	4.41	8.33	4	22.87	24.17	16.89
101	111	4.41	28.22	5.95	52.71	55.69	38.93
101	112	4.41	14.5	3.06	30.02	31.72	22.17
101	113	4.41	17.27	5.77	37.5	39.63	27.7
102	100	52.58	63.43	28.59	197.42	208.92	145.8
102	101	50.65	27.44	25.75	141.81	150.07	104.73
102	102	49.18	85.43	79.87	292.84	309.91	216.28
102	103	54.24	88.96	27.34	232.8	246.36	171.93
102	104	44.99	21.24	32.1	134.3	142.12	99.18
102	110	4.41	8.35	4	22.88	24.22	16.9
102	111	4.55	29.16	6.14	54.37	57.54	40.16
102	112	7	23.07	4.86	47.68	50.46	35.21
102	113	3.5	13.74	4.58	29.78	31.52	22
\.


--
-- PostgreSQL database dump complete
--

