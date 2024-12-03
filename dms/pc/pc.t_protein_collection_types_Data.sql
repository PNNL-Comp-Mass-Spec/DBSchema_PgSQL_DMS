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
-- Data for Name: t_protein_collection_types; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_protein_collection_types (collection_type_id, type, display, description) FROM stdin;
1	protein_file	Loaded Protein File	Loaded from pre-existing (possibly annotated) protein source file
2	nucleotide_sequence	Translated File	Translated locally from genomic sequence into a stored collection
3	combined	Combined	Made from subsets (or the entirety) of one or more existing static collections
4	contaminant	Contaminants	Potential contaminant proteins
5	internal_standard	Internal Standard	Internal standard proteins
6	old_contaminant	Old Contaminants	Potential contaminant proteins
\.


--
-- Name: t_protein_collection_types_collection_type_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_protein_collection_types_collection_type_id_seq', 6, true);


--
-- PostgreSQL database dump complete
--

