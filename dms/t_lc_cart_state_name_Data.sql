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
-- Data for Name: t_lc_cart_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_lc_cart_state_name (cart_state_id, cart_state) FROM stdin;
1	(unknown)
2	In Service
3	Out of Service
10	Retired
\.


--
-- PostgreSQL database dump complete
--

