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
-- Data for Name: t_archived_file_types; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_archived_file_types (archived_file_type_id, file_type_name, description) FROM stdin;
1	static	Static collection, listed in T_Protein_Collections
2	dynamic	Transient, runtime generated collection, not listed in T_Protein_Collections
\.


--
-- Name: t_archived_file_types_archived_file_type_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_archived_file_types_archived_file_type_id_seq', 2, true);


--
-- PostgreSQL database dump complete
--

