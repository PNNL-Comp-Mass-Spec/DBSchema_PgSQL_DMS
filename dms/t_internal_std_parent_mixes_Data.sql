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
-- Data for Name: t_internal_std_parent_mixes; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_internal_std_parent_mixes (parent_mix_id, name, description, protein_collection_name) FROM stdin;
1	PepChromeA	5 elution time marker peptides	PCQ_ETJ_2004-01-21
2	MiniProteomeA	5 proteins added prior to digestion (development work)	MiniProteomeA_2004-10-26
3	MiniProteomeB	3 proteins added prior to digestion; 6 peptides after digestion	MP_06_01
4	MiniProteomeC	Official mini proteome (3 proteins added prior to digestion)	MP_06_01
5	QC_05_03	QC Standards mixture, 2005 batch	PCQ_ETJ_2004-01-21
6	ADHYeast	Alcohol Dehydrogenase (yeast), pre-digested	ADH_Yeast
\.


--
-- PostgreSQL database dump complete
--

