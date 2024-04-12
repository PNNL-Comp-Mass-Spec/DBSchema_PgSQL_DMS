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
-- Data for Name: t_filter_set_types; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_filter_set_types (filter_type_id, filter_type_name) FROM stdin;
1	Peptide DB Import filter
2	Mass Tag DB Import filter
3	PMT Quality Score Filter
\.


--
-- Name: t_filter_set_types_filter_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_filter_set_types_filter_type_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

