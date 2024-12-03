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
-- Data for Name: t_creation_option_keywords; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_creation_option_keywords (keyword_id, keyword, display, description, default_value, is_required) FROM stdin;
1	seq_direction	Sequence Direction	\N	forward	1
2	filetype	Output Format	\N	fasta	1
\.


--
-- Name: t_creation_option_keywords_keyword_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_creation_option_keywords_keyword_id_seq', 2, true);


--
-- PostgreSQL database dump complete
--

