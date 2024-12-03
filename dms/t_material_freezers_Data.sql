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
-- Data for Name: t_material_freezers; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_material_freezers (freezer_id, freezer, freezer_tag, comment) FROM stdin;
58	-20 BSF1206 Staging A	-20_BSF1206_Staging_A	BSF/1206 Staging Freezer A (prepped samples for transfer)
60	-20 BSF1206 Staging B	-20_BSF1206_Staging_B	BSF/1206 Staging Freezer B (completed sample short-term storage)
61	-20 BSF1215 Staging A	-20_BSF1215_Staging_A	BSF/1215 Staging Freezer A (prepped samples for transfer)
67	-20 BSF1229 Staging A	-20_BSF1229_Staging_A	BSF/1229 Staging Freezer A (prepped samples for transfer)
63	-20 BSF2240 Staging A	-20_BSF2240_Staging_A	BSF/2240 Staging Freezer A (prepped samples for transfer)
53	-20 EMSL1521 Staging A	-20_EMSL1521_Staging_A	EMSL/1521 Staging Freezer A (peptides); located in the service corridor (EMSL 1450)
56	-20 EMSL1521 Staging B	-20_EMSL1521_Staging_B	EMSL/1521 Staging Freezer B (completed boxes); located in the service corridor (EMSL 1450)
57	-20 EMSL1521 Staging C	-20_EMSL1521_Staging_C	EMSL/1521 Staging Freezer C (IMS, lipids, metabolites); located in the service corridor (EMSL 1450)
36	-20 Met Staging	-20_Met_Staging	Located in BSF/1215
26	-20 Metabolite	20Met	Located in BSF/1215
39	-20 Staging 1206	-20_Staging_1206	Located in BSF/1206
11	-20 Staging 1521	-20_Staging	Located in the EMSL/1521 service corridor
20	-70 BSF1215A	1215A	Stirling Ultracold, model SU780XLE, property WD38248 (-70 BSF1215A replaces -80 BSF1215A)
13	-80 BSF1206A	1206A	Stirling Ultracold, model SU780UE, property WD56563
14	-80 BSF1206B	1206B	Stirling Ultracold, model SU780XLE, property WD85655, serial 18111-12653
40	-80 BSF1206B Revco	1206B_Revco	Thermo Scientific / REVCO, model ULT 2586-5-D34, contents transferred to 1206B (Stirling) in December 2018
15	-80 BSF1206C	1206C	Thermo Scientific / REVCO, model ULT 2586-4-A46, property PT15127
16	-80 BSF1208A	1208A	Stirling Ultracold, model SU780XLE, property WD83575, serial 19080-10442
43	-80 BSF1208A_Old	1208A_Old	Revco Model ULT2586-5-A39
17	-80 BSF1208B	1208B	Eppendorf / New Brunswick U700, model U9280-0000, property WD56280
32	-80 BSF1208C	1208C	Thermo Scientific / REVCO, model ULT 2586-10-A48, property PT27095 (backup freezer)
31	-80 BSF1208D	1208D	Stirling Ultracold, model SU780XLE, property WD91947, serial 23090-22693 (replaces WD85272, serial 17080-01164)
38	-80 BSF1208E	1208E	Stirling Ultracold, model SU780XLE, property WD38275, serial 18031-11205
49	-80 BSF1208F	1208F	Stirling Ultracold, model SU780XLE, property WD85280, serial 21090-16621
41	-80 BSF1208F_Old	1208F_Old	Stirling Ultracold, model SU780XLE, property WD85409, serial 18101-12398 (renamed to 2222A in June 2021, then 2222B in October 2021)
18	-80 BSF1211A	1211A	\N
19	-80 BSF1213A	1213A	\N
21	-80 BSF1232A	1232A	\N
51	-80 BSF1246A	1246A	Stirling Ultracold, model SU780XLE, property PT15996, serial 22120-20771
45	-80 BSF2222A	2222A	BSL1 freezer; Stirling Ultracold, model SU780XLE, property WD86042, serial 21090-16573
44	-80 BSF2222B	2222B	BSL2 freezer; Stirling Ultracold, model SU780XLE, property WD85409, serial 18101-12398
66	-80 BSF2240A	2240A	Stirling Ultracold, model SU780XLE, serial 23110-23027
27	-80 BSF2240A_Old	2240A_Old	Eppendorf / New Brunswick U700, model U9280-0000, serial F700DN600956
28	-80 BSF2240B	2240B	Stirling Ultracold, model SU780UE, property WD56562, serial 1602.01948
33	-80 BSF2240C	2240C	Eppendorf / New Brunswick U700, model U101 -86 Innova, serial F101EN030856
50	-80 EMSL1310A	1310A	Thermo Scientific TSX ULT, model TSX40086A, property TBD, serial 1125683801220420
22	-80 EMSL1450A	1450A	Eppendorf / New Brunswick U700, model U9280-0000, property WD76704, serial F700BP800266
23	-80 EMSL1450B	1450B	Stirling Ultracold, model SU780UE, property WD81837, serial 150601104
24	-80 EMSL1450C	1450C	Thermo Scientific / REVCO, model ULT 2586-4-A46, property WD37819, serial 12855310109090
25	-80 EMSL1450D	1450D	Eppendorf / New Brunswick U700, model U9280-0000, property WD81398, serial F700DG400858
42	-80 EMSL1450E	1450E	USDA Regulated Soils, Stirling Ultracold, model SU780XLE, Property WD82970, serial 19070-10165
52	-80 EMSL1521A	1521A	BSL2 freezer; Stirling Ultracold, model SU105UE, serial 2301.03789
12	-80 Staging	-80_Staging	\N
34	Phosphopep Staging	Phosphopep_Staging	Actually in location 1450A.2.1
35	QC Staging	QC_Staging	Actually in location 1450A.2.2
10	na	None	\N
\.


--
-- Name: t_material_freezers_freezer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_material_freezers_freezer_id_seq', 67, true);


--
-- PostgreSQL database dump complete
--

