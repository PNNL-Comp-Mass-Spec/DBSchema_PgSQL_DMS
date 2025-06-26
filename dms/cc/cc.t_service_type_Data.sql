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
-- Data for Name: t_service_type; Type: TABLE DATA; Schema: cc; Owner: d3l243
--

COPY cc.t_service_type (service_type_id, service_type, service_description) FROM stdin;
0	Undefined	Undefined
1	None	Not a cost center tracked requested run or dataset
2	Peptides: Short advanced MS	Astral, nanoPOTS, separation time < 60 minutes
3	Peptides: Short standard MS	HFX, Lumos, Eclipse, Exploris, SRM, separation time < 60 minutes
4	Peptides: Long advanced MS	Astral, separation time >= 60 minutes
5	Peptides: Long standard MS	HFX, Lumos, Eclipse, Exploris, nanoPOTS, separation time >= 60 minutes
6	Peptides: Screening MS (Ulta Fast)	All Orbitraps, separation time < 5 minutes, or infusion
7	Lipids and Metabolites	Lipids and Metabolites
8	GC-MS	GC-MS
9	MALDI	MALDI (run count = hr count)
25	Ambiguous	Unable to auto-determine the correct service type
\.


--
-- PostgreSQL database dump complete
--

