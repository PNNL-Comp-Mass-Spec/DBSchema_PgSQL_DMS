--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
-- Dumped by pg_dump version 16.1

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
-- Data for Name: t_instrument_ops_role; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_ops_role (role, description) FROM stdin;
InSilico	In-silico instrument for tracking DMS_Pipeline_Data
Offsite	Non-PNNL instrument (Broad, MIT, etc.)
Production	Production, routine usage
QC	QC (tag no longer used)
Research	Research
SamplePrep	Sample preparation
Transcriptomics	RNA / DNA Sequencing
Unknown	Unknown usage
Unused	No longer in use
\.


--
-- PostgreSQL database dump complete
--

