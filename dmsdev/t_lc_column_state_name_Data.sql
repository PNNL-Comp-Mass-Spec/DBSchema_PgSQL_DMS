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
-- Data for Name: t_lc_column_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_lc_column_state_name (column_state_id, column_state) FROM stdin;
0	na
1	New
2	Active
3	Retired
\.


--
-- PostgreSQL database dump complete
--

