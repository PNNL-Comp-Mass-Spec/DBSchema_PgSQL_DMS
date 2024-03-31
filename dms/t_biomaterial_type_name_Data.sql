--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: t_biomaterial_type_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_biomaterial_type_name (biomaterial_type_id, biomaterial_type) FROM stdin;
109	Air
105	Biofluid
104	Community
2	Eukaryote
107	Genetically modified eukaryote
106	Genetically modified prokaryote
108	Genetically modified virus
103	Metabolite standards
114	Miscellaneous or artificial
113	Plant-associated
1	Prokaryote
102	Protein/peptide standards
112	Sediment
110	Soil
101	Viral
115	Wastewater/sludge
111	Water
\.


--
-- Name: t_biomaterial_type_name_biomaterial_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_biomaterial_type_name_biomaterial_type_id_seq', 115, true);


--
-- PostgreSQL database dump complete
--

