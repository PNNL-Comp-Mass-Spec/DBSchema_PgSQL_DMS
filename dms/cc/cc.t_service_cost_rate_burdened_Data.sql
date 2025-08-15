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
-- Data for Name: t_service_cost_rate_burdened; Type: TABLE DATA; Schema: cc; Owner: d3l243
--

COPY cc.t_service_cost_rate_burdened (cost_group_id, funding_agency, service_type_id, base_rate_per_run, pdm, general_and_administration, safeguards_and_security, fee, ldrd, facilities) FROM stdin;
101	DOE	100	139.98	5.46	39.12	4.8	1.29	6.29	0
101	DOE	101	104.85	4.09	29.31	3.6	0.97	4.71	0
101	DOE	102	219.77	8.57	61.42	7.54	2.03	9.88	0
101	DOE	103	159.87	6.23	44.68	5.48	1.48	7.19	0
101	DOE	104	199.72	7.79	55.82	6.85	1.84	8.98	0
101	DOE	110	17.55	0.68	4.91	0.6	0.16	0.79	0
101	DOE	111	39.92	1.56	11.16	1.37	0.37	1.79	0
101	DOE	112	22.96	0.9	6.42	0.79	0.21	1.03	0
101	DOE	113	28.5	1.11	7.97	0.98	0.26	1.28	0
101	HHS/DOD	100	139.98	5.46	39.12	4.8	1.29	6.29	1.97
101	HHS/DOD	101	104.85	4.09	29.31	3.6	0.97	4.71	1.48
101	HHS/DOD	102	219.77	8.57	61.42	7.54	2.03	9.88	3.09
101	HHS/DOD	103	159.87	6.23	44.68	5.48	1.48	7.19	2.25
101	HHS/DOD	104	199.72	7.79	55.82	6.85	1.84	8.98	2.81
101	HHS/DOD	110	17.55	0.68	4.91	0.6	0.16	0.79	0.25
101	HHS/DOD	111	39.92	1.56	11.16	1.37	0.37	1.79	0.56
101	HHS/DOD	112	22.96	0.9	6.42	0.79	0.21	1.03	0.32
101	HHS/DOD	113	28.5	1.11	7.97	0.98	0.26	1.28	0.4
101	LDRD	100	139.98	0	0	0	0.98	0	0
101	LDRD	101	104.85	0	0	0	0.73	0	0
101	LDRD	102	219.77	0	0	0	1.54	0	0
101	LDRD	103	159.87	0	0	0	1.12	0	0
101	LDRD	104	199.72	0	0	0	1.4	0	0
101	LDRD	110	17.55	0	0	0	0.12	0	0
101	LDRD	111	39.92	0	0	0	0.28	0	0
101	LDRD	112	22.96	0	0	0	0.16	0	0
101	LDRD	113	28.5	0	0	0	0.2	0	0
\.


--
-- PostgreSQL database dump complete
--

