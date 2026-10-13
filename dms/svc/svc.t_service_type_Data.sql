--
-- PostgreSQL database dump
--

-- Dumped from database version 18.6
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
-- Data for Name: t_service_type; Type: TABLE DATA; Schema: svc; Owner: d3l243
--

COPY svc.t_service_type (service_type_id, service_type, service_description, abbreviation, active) FROM stdin;
0	Undefined	Undefined	Undefined	1
1	None	Not a service center tracked requested run or dataset	None	1
25	Ambiguous	Unable to auto-determine the correct service type	Ambiguous	1
100	Peptides: Advanced MS	Astral, nanoPOTS, or timsTOF SCP	PepSA	1
101	Peptides: Short Standard MS	HFX, Lumos, Eclipse, or Exploris with separation time <= 60 minutes; all SRM and MRM	PepSS	1
102	Peptides: Long Advanced MS	Astral or timsTOF SCP with separation time > 60 minutes (discontinued in FY27)	PepLA	0
103	Peptides: Long Standard MS	HFX, Lumos, Eclipse, Exploris, or nanoPOTS with separation time > 60 minutes	PepLS	1
104	MALDI	MALDI (run count = hr count)	MALDI	1
110	Peptides: Screening MS	All Orbitraps, separation time <= 5 minutes (ultra fast), or infusion	PepScreen	1
111	Lipids	Lipids (discontinued in FY27)	Lipid	0
112	Metabolites	Metabolites (discontinued in FY27)	Metab	0
113	GC-MS	GC-MS	GCMS	1
114	Lipids and Metabolites	Lipids and Metabolites	LipidMetab	1
\.


--
-- PostgreSQL database dump complete
--

