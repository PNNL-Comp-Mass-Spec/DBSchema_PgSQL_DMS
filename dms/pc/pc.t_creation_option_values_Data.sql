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
-- Data for Name: t_creation_option_values; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_creation_option_values (value_id, value_string, display, description, keyword_id) FROM stdin;
1	forward	Forward	Sequences as read from the database	1
2	reversed	Reversed	Sequences character reversed	1
3	scrambled	Scrambled	Sequences randomized within a protein	1
4	fasta	Standard FASTA	Standard FASTA file in ASCII text format	2
5	fastapro	FASTA.pro file for X!Tandem	The FASTA.pro file is a binary form of an original FASTA file	2
8	decoy	Decoy	Combined Forward/Reverse FASTA file	1
9	decoyX	DecoyX	Combined Forward/Reverse FASTA file using XXX.	1
\.


--
-- Name: t_creation_option_values_value_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_creation_option_values_value_id_seq', 9, true);


--
-- PostgreSQL database dump complete
--

