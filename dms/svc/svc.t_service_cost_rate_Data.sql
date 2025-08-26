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
-- Data for Name: t_service_cost_rate; Type: TABLE DATA; Schema: svc; Owner: d3l243
--

COPY svc.t_service_cost_rate (cost_group_id, service_type_id, indirect_per_run, direct_per_run, non_labor_per_run, doe_burdened_rate_per_run, hhs_burdened_rate_per_run, ldrd_burdened_rate_per_run) FROM stdin;
101	100	52.63	60.61	26.74	196.94	198.91	140.96
101	101	52.63	27.22	25	147.53	149.01	105.58
101	102	52.63	87.26	79.87	309.21	312.3	221.31
101	103	52.63	82.44	24.79	224.93	227.18	160.99
101	104	52.63	59.37	87.72	281	283.81	201.12
101	110	5.03	8.52	4	24.69	24.94	17.67
101	111	5.03	28.94	5.95	56.17	56.73	40.2
101	112	5.03	14.87	3.06	32.31	32.63	23.12
101	113	5.03	17.7	5.77	40.1	40.5	28.7
\.


--
-- PostgreSQL database dump complete
--

