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
-- Data for Name: t_data_analysis_request_type_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_data_analysis_request_type_name (analysis_type) FROM stdin;
Lipidomics
Metabolomics
Proteomics
\.


--
-- PostgreSQL database dump complete
--

