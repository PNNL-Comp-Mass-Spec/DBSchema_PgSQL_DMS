--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.1

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
-- Data for Name: t_myemsl_state; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_myemsl_state (myemsl_state, myemsl_state_name) FROM stdin;
0	Not in MyEMSL
1	Submitted to MyEMSL
2	Verified in MyEMSL
\.


--
-- PostgreSQL database dump complete
--

