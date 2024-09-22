--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

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
-- Data for Name: t_sample_labelling; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_sample_labelling (label_id, label, reporter_mz_min, reporter_mz_max) FROM stdin;
0	Unknown	\N	\N
1	none	\N	\N
2	N14/N15	\N	\N
3	ICAT	\N	\N
4	PhIAT	\N	\N
5	PEO-Biotin	\N	\N
6	O18	\N	\N
7	Sulfo-NHS-LC-Biotin	\N	\N
8	Cleavable ICAT	\N	\N
9	SP-ICAT	\N	\N
10	PhIST	\N	\N
11	Leu_C13N15	\N	\N
12	Phe_C13	\N	\N
13	iTRAQ	114.1112	117.115
14	iTRAQ8	113.1079	121.1221
15	TMT2	126.1277	127.1316
16	TMT6	126.1277	131.1382
17	12C/13C	\N	\N
18	TMT10	126.1277	131.1382
19	TMT0	\N	\N
20	ABP	\N	\N
21	B12-ABP	\N	\N
22	TMT11	126.1277	131.1445
23	TMT16	126.1277	134.1483
24	PCGalNAz	204.0872	503.21017
25	TMT18	126.1277	135.152
26	TMT32	126.1277	135.161
27	TMT35	126.1277	135.161
\.


--
-- PostgreSQL database dump complete
--

