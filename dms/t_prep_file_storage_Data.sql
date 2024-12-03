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
-- Data for Name: t_prep_file_storage; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_prep_file_storage (storage_id, purpose, path_local_root, path_shared_root, path_web_root, path_archive_root, state, created) FROM stdin;
10	Sample_Prep	F:\\Sample_Prep_Repository\\	\\\\proto-7\\Sample_Prep_Repository\\	\N	\N	Active	2010-04-28 09:53:38
\.


--
-- Name: t_prep_file_storage_storage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_prep_file_storage_storage_id_seq', 10, true);


--
-- PostgreSQL database dump complete
--

