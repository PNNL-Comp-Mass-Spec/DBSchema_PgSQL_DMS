--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
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
-- Data for Name: t_service_cost_rate_burdened; Type: TABLE DATA; Schema: svc; Owner: d3l243
--

COPY svc.t_service_cost_rate_burdened (cost_group_id, funding_agency, service_type_id, base_rate_per_run, pdm, general_and_administration, safeguards_and_security, fee, ldrd, facilities) FROM stdin;
101	DOE	100	135.15	5.27	37.07	0	1.6	5.55	0
101	DOE	101	100.78	3.93	27.64	0	1.19	4.14	0
101	DOE	102	214.35	8.36	58.8	0	2.53	8.81	0
101	DOE	103	154.52	6.03	42.38	0	1.83	6.35	0
101	DOE	104	107.45	4.19	29.47	0	1.27	4.41	0
101	DOE	110	16.74	0.65	4.59	0	0.2	0.69	0
101	DOE	111	38.58	1.5	10.58	0	0.46	1.58	0
101	DOE	112	21.97	0.86	6.03	0	0.26	0.9	0
101	DOE	113	27.45	1.07	7.53	0	0.32	1.13	0
101	HHS/DOD	100	135.15	5.27	37.07	4.63	1.6	5.7	5.68
101	HHS/DOD	101	100.78	3.93	27.64	3.46	1.19	4.25	4.24
101	HHS/DOD	102	214.35	8.36	58.8	7.35	2.53	9.03	9.01
101	HHS/DOD	103	154.52	6.03	42.38	5.3	1.83	6.51	6.5
101	HHS/DOD	104	107.45	4.19	29.47	3.68	1.27	4.53	4.52
101	HHS/DOD	110	16.74	0.65	4.59	0.57	0.2	0.71	0.7
101	HHS/DOD	111	38.58	1.5	10.58	1.32	0.46	1.63	1.62
101	HHS/DOD	112	21.97	0.86	6.03	0.75	0.26	0.93	0.92
101	HHS/DOD	113	27.45	1.07	7.53	0.94	0.32	1.16	1.15
101	LDRD	100	135.15	0	0	0	1.22	0	0
101	LDRD	101	100.78	0	0	0	0.91	0	0
101	LDRD	102	214.35	0	0	0	1.93	0	0
101	LDRD	103	154.52	0	0	0	1.39	0	0
101	LDRD	104	107.45	0	0	0	0.97	0	0
101	LDRD	110	16.74	0	0	0	0.15	0	0
101	LDRD	111	38.58	0	0	0	0.35	0	0
101	LDRD	112	21.97	0	0	0	0.2	0	0
101	LDRD	113	27.45	0	0	0	0.25	0	0
\.


--
-- PostgreSQL database dump complete
--

