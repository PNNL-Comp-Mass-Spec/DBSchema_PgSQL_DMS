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
-- Data for Name: t_instrument_group_allocation_tag; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_group_allocation_tag (allocation_tag, allocation_description) FROM stdin;
EXA	Exactive
FT	FTICR
GC	GC-MS
IMS	Ion Mobility
LTQ	LTQ
MAL	MALDI
NMR	NMR
None	No allocation tag
ORB	Orbitrap, Velos Orbitrap, Orbitrap Fusion Lumos, Eclipse
QQQ	Triple Quad, QTrap, Altis
SEQ	RNA / DNA Sequencers
TOF	Time of Flight
\.


--
-- PostgreSQL database dump complete
--

