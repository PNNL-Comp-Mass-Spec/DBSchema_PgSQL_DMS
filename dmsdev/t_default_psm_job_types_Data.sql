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
-- Data for Name: t_default_psm_job_types; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_default_psm_job_types (job_type_id, job_type_name, job_type_description) FROM stdin;
1	Low Res MS1	Data acquired with low resolution MS1 spectra, typically using an LTQ
2	High Res MS1	Data acquired with high resolution MS1 spectra, typically an Orbitrap or LTQ-FT
3	iTRAQ 4-plex	iTRAQ labeled sample analyzed with HCD on an Orbitrap or LTQ-FT
4	iTRAQ 8-plex	iTRAQ labeled sample analyzed with HCD on an Orbitrap or LTQ-FT
5	TMT 6-plex	TMT 6-plex (or 10-plex or 11-plex) labeled sample analyzed with HCD on an Orbitrap or LTQ-FT
6	TMT 16-plex	TMT 16-plex labeled sample analyzed with HCD on an Orbitrap or LTQ-FT
7	TMT Zero	TMT 0 labeled sample analyzed with HCD on an Orbitrap or LTQ-FT
\.


--
-- PostgreSQL database dump complete
--

