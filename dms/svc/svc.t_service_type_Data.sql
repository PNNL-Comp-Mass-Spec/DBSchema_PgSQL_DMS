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
-- Data for Name: t_service_type; Type: TABLE DATA; Schema: svc; Owner: d3l243
--

COPY svc.t_service_type (service_type_id, service_type, service_description, abbreviation) FROM stdin;
0	Undefined	Undefined	Undefined
1	None	Not a service center tracked requested run or dataset	None
25	Ambiguous	Unable to auto-determine the correct service type	Ambiguous
100	Peptides: Short Advanced MS	Astral, nanoPOTS, timsTOF SCP, separation time <= 60 minutes	PepSA
101	Peptides: Short Standard MS	HFX, Lumos, Eclipse, Exploris, SRM, MRM, separation time <= 60 minutes	PepSS
102	Peptides: Long Advanced MS	Astral, nanoPOTS, timsTOF SCP, separation time > 60 minutes	PepLA
103	Peptides: Long Standard MS	HFX, Lumos, Eclipse, Exploris, separation time > 60 minutes	PepLS
104	MALDI	MALDI (run count = hr count)	MALDI
110	Peptides: Screening MS	All Orbitraps, separation time <= 5 minutes (ultra fast), or infusion	PepScreen
111	Lipids	Lipids	Lipid
112	Metabolites	Metabolites	Metab
113	GC-MS	GC-MS	GCMS
\.


--
-- PostgreSQL database dump complete
--

