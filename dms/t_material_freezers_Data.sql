--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
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

COPY public.t_material_freezers (freezer_id, freezer, freezer_tag, comment, status) FROM stdin;
58	-20 BSF1206 Staging A	-20_BSF1206_Staging_A	BSF/1206 Staging Freezer A (prepped samples for transfer)	Active
60	-20 BSF1206 Staging B	-20_BSF1206_Staging_B	BSF/1206 Staging Freezer B (completed sample short-term storage)	Active
61	-20 BSF1215 Staging A	-20_BSF1215_Staging_A	BSF/1215 Staging Freezer A (prepped lipids for transfer)	Active
36	-20 BSF1215 Staging B	-20_BSF1215_Staging_B	BSF/1215 Staging Freezer B (prepped metabolites for transfer)	Active
67	-20 BSF1229 Staging A	-20_BSF1229_Staging_A	BSF/1229 Staging Freezer A (prepped samples for transfer)	Active
68	-20 BSF2235 Staging A	-20_BSF2235_Staging_A	BSF/2235 Staging Freezer A (prepped samples for Astral)	Active
63	-20 BSF2240 Staging A	-20_BSF2240_Staging_A	BSF/2240 Staging Freezer A (prepped samples for transfer)	Active
53	-20 EMSL1521 Staging A	-20_EMSL1521_Staging_A	EMSL/1521 Staging Freezer A (peptides); located in the service corridor (EMSL 1450)	Active
56	-20 EMSL1521 Staging B	-20_EMSL1521_Staging_B	EMSL/1521 Staging Freezer B (completed boxes); located in the service corridor (EMSL 1450)	Active
57	-20 EMSL1521 Staging C	-20_EMSL1521_Staging_C	EMSL/1521 Staging Freezer C (IMS, lipids, metabolites); located in the service corridor (EMSL 1450)	Active
26	-20 Metabolite	20Met	Located in BSF/1215; for metabolites	Active
39	-20 Staging 1206	-20_Staging_1206	Located in BSF/1206 for staging	Active
11	-20 Staging 1521	-20_Staging	Located in the EMSL/1521 service corridor	Active
20	-70 BSF1215A	1215A	Stirling Ultracold, model SU780XLE, property WD38248 (-70 BSF1215A replaces -80 BSF1215A)	Active
13	-80 BSF1206A	1206A	Stirling Ultracold, model SU780UE, property WD56563	Active
14	-80 BSF1206B	1206B	Stirling Ultracold, model SU780XLE, property WD85655, serial 18111-12653	Active
40	-80 BSF1206B Revco	1206B_Revco	Thermo Scientific / REVCO, model ULT 2586-5-D34, contents transferred to 1206B (Stirling) in December 2018	Active
15	-80 BSF1206C	1206C	Thermo Scientific / REVCO, model ULT 2586-4-A46, property PT15127; compressor failed 2025-05-13	Active
16	-80 BSF1208A	1208A	Stirling Ultracold, model SU780XLE, property WD83575, serial 19080-10442	Active
43	-80 BSF1208A_Old	1208A_Old	Revco Model ULT2586-5-A39	Active
17	-80 BSF1208B	1208B	Eppendorf / New Brunswick U700, model U9280-0000, property WD56280	Active
32	-80 BSF1208C	1208C	Thermo Scientific / REVCO, model ULT 2586-10-A48, property PT27095 (backup freezer)	Active
31	-80 BSF1208D	1208D	Stirling Ultracold, model SU780XLE, property WD91947, serial 23090-22693 (replaces WD85272, serial 17080-01164)	Active
38	-80 BSF1208E	1208E	Stirling Ultracold, model SU780XLE, property WD38275, serial 18031-11205	Active
49	-80 BSF1208F	1208F	Stirling Ultracold, model SU780XLE, property WD85280, serial 21090-16621	Active
41	-80 BSF1208F_Old	1208F_Old	Stirling Ultracold, model SU780XLE, property WD85409, serial 18101-12398 (renamed to 2222A in June 2021, then 2222B in October 2021)	Active
18	-80 BSF1211A	1211A	\N	Active
19	-80 BSF1213A	1213A	\N	Active
21	-80 BSF1232A	1232A	\N	Active
51	-80 BSF1246A	1246A	Stirling Ultracold, model SU780XLE, property PT15996, serial 22120-20771	Active
45	-80 BSF2222A	2222A	BSL1 freezer; Stirling Ultracold, model SU780XLE, property WD86042, serial 21090-16573	Active
44	-80 BSF2222B	2222B	BSL2 freezer; Stirling Ultracold, model SU780XLE, property WD85409, serial 18101-12398	Active
66	-80 BSF2240A	2240A	Stirling Ultracold, model SU780XLE, serial 23110-23027	Active
27	-80 BSF2240A_Old	2240A_Old	Eppendorf / New Brunswick U700, model U9280-0000, serial F700DN600956	Active
28	-80 BSF2240B	2240B	Stirling Ultracold, model SU780UE, property WD56562, serial 1602.01948	Active
33	-80 BSF2240C	2240C	Eppendorf / New Brunswick U700, model U101 -86 Innova, serial F101EN030856	Active
50	-80 EMSL1310A	1310A	Thermo Scientific TSX ULT, model TSX40086A, property TBD, serial 1125683801220420	Active
69	-80 EMSL1350Antarctica	1350A	USDA -80C freezer in 1350 service corridor (locked)	Active
70	-80 EMSL1350Belarus	1350B	-80C freezer in 1350 service corridor for long term storage	Active
73	-80 EMSL1350Estonia	1350E	-80C freezer in 1350 service corridor for long term storage	Active
74	-80 EMSL1350Finland	1350F	-80C freezer in 1350 service corridor for long term storage	Active
75	-80 EMSL1350Greenland	1350G	-80C freezer in 1350 service corridor left empty (locked) as a back-up in case others break down	Active
71	-80 EMSL1413Canada	1413C	-80C freezer inside the lab	Active
72	-80 EMSL1413Denmark	1413D	-80C freezer inside the lab	Active
22	-80 EMSL1450A	1450A	Eppendorf / New Brunswick U700, model U9280-0000, property WD76704, serial F700BP800266	Active
23	-80 EMSL1450B	1450B	Stirling Ultracold, model SU780UE, property WD81837, serial 150601104	Active
24	-80 EMSL1450C	1450C	Thermo Scientific / REVCO, model ULT 2586-4-A46, property WD37819, serial 12855310109090	Active
25	-80 EMSL1450D	1450D	Eppendorf / New Brunswick U700, model U9280-0000, property WD81398, serial F700DG400858	Active
42	-80 EMSL1450E	1450E	USDA Regulated Soils, Stirling Ultracold, model SU780XLE, Property WD82970, serial 19070-10165	Active
52	-80 EMSL1521A	1521A	BSL2 freezer; Stirling Ultracold, model SU105UE, serial 2301.03789	Active
12	-80 Staging	-80_Staging	\N	Active
34	Phosphopep Staging	Phosphopep_Staging	Actually in location 1450A.2.1	Active
35	QC Staging	QC_Staging	Actually in location 1450A.2.2	Active
10	na	None	\N	Active
\.


--
-- Name: t_material_freezers_freezer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_material_freezers_freezer_id_seq', 75, true);


--
-- PostgreSQL database dump complete
--

