--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
-- Dumped by pg_dump version 16.1

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
-- Data for Name: t_output_sequence_types; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_output_sequence_types (output_sequence_type_id, output_sequence_type, display, description) FROM stdin;
1	forward	Normal Sequences	Sequences as read from the database
2	reversed	Reversed Sequences	Sequences character reversed
3	scrambled	Scrambled Sequences	Sequences randomized within a protein
\.


--
-- Name: t_output_sequence_types_output_sequence_type_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_output_sequence_types_output_sequence_type_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

