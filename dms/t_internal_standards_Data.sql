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
-- Data for Name: t_internal_standards; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_internal_standards (internal_standard_id, parent_mix_id, name, description, type, active) FROM stdin;
0	\N	unknown	status uncertain	All	I
1	\N	none	Nothing added	All	A
2	1	PepChromeA	5 elution time marker peptides	Postdigest	A
3	2	MiniProteomeA	5 proteins added prior to digestion (development work)	Predigest	I
4	3	MiniProteomeB	3 proteins added prior to digestion; 6 peptides after digestion	Predigest	I
5	4	MP_05_01	Official mini proteome, October 2005 batch	Predigest	I
6	4	MP_06_01	Official mini proteome, March 2006 batch	Predigest	I
7	4	mini-proteome	General mini-proteome	Predigest	I
8	4	MP_06_02	Official mini proteome, October 2006 batch	Predigest	I
9	4	MP_06_03	Official mini proteome, December 2006 batch	Predigest	I
10	5	QC_05_03	QC Standards mixture, 2005 batch	Predigest	I
11	4	MP_07_01	Official mini proteome, January 2007 batch	Predigest	I
12	4	MP_07_02	Official mini proteome, April 2007 batch	Predigest	I
13	4	MP_07_03	Official mini proteome, July 2007 batch	Predigest	I
14	4	MP_07_04	Official mini proteome, February 2008 batch	Predigest	I
15	6	ADHYeast	Alcohol Dehydrogenase (Yeast)	Postdigest	I
16	4	MP_08_01	Official mini proteome, July 2008 batch	Predigest	I
17	6	ADHYeast_082308	Alcohol Dehydrogenase, August 2008 batch	Postdigest	I
18	4	MP_09_01	Official mini proteome, 2009 batch #1	Predigest	I
19	4	MP_09_02	Official mini proteome, 2009 batch #2	Predigest	I
20	4	MP_09_03	Official mini proteome, 2009 batch #3	Predigest	I
21	4	MP_10_01	Official mini proteome, 2010 batch #1	Predigest	I
22	4	MP_10_02	Official mini proteome, 2010 batch #2	Predigest	I
23	4	MP_10_03	Official mini proteome, 2010 batch #3	Predigest	I
24	4	MP_10_04	Official mini proteome, 2010 batch #4	Predigest	I
25	6	ADHYeast_031411	Alcohol Dehydrogenase, March 2011 batch	Postdigest	A
26	4	MP_11_01	Official mini proteome, 2011 batch #1	Predigest	A
27	4	MP_12_01	Official mini proteome, 2012 batch #1	Predigest	A
\.


--
-- Name: t_internal_standards_internal_standard_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_internal_standards_internal_standard_id_seq', 27, true);


--
-- PostgreSQL database dump complete
--

