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
-- Data for Name: t_modification_types; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_modification_types (mod_type_symbol, description, mod_type_synonym) FROM stdin;
D	Dynamic Modification	Dyn
I	Isotopic Modification	Iso
P	Terminal Protein Static Modification	ProtTerm
S	Static Modification	Stat
T	Terminal Peptide Static Modification	PepTerm
\.


--
-- PostgreSQL database dump complete
--

