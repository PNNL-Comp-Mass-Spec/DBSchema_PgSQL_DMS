--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
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
-- Data for Name: t_reference_compound_type_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_reference_compound_type_name (compound_type_id, compound_type_name) FROM stdin;
100	Compound
101	Protein/peptide standards
102	Metabolite standards
\.


--
-- Name: t_reference_compound_type_name_compound_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_reference_compound_type_name_compound_type_id_seq', 102, true);


--
-- PostgreSQL database dump complete
--

