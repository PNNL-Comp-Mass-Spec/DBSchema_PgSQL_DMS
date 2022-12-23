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
-- Data for Name: t_charge_code_activation_state; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_charge_code_activation_state (activation_state, activation_state_name) FROM stdin;
0	Active
1	Active, unused
2	Active, old
3	Inactive, used
4	Inactive, unused
5	Inactive, old
\.


--
-- PostgreSQL database dump complete
--

