--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

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
-- Data for Name: schema_version; Type: TABLE DATA; Schema: pgwatch2; Owner: pgwatch2
--

COPY pgwatch2.schema_version (sv_tag, sv_created_on) FROM stdin;
1.6.2	2019-10-04 22:09:29.423817-07
\.


--
-- PostgreSQL database dump complete
--

