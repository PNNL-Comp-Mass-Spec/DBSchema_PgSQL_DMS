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
-- Data for Name: config; Type: TABLE DATA; Schema: admin; Owner: pgwatch2
--

COPY admin.config (key, value, created_on, last_modified_on) FROM stdin;
timescale_chunk_interval	2 days	2024-04-15 19:51:26.245361-07	\N
timescale_compress_interval	1 day	2024-04-15 19:51:26.245361-07	\N
\.


--
-- PostgreSQL database dump complete
--

