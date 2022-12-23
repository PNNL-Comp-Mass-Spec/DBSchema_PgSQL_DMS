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
-- Data for Name: t_experiment_plex_channel_type_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_experiment_plex_channel_type_name (channel_type_id, channel_type_name) FROM stdin;
0	Empty
1	Sample
2	Reference
3	Boost
\.


--
-- PostgreSQL database dump complete
--

