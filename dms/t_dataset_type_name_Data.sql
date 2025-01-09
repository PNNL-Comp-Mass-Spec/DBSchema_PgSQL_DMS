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
-- Data for Name: t_dataset_type_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_type_name (dataset_type_id, dataset_type, description, active) FROM stdin;
52	1D-C	NMR analysis	0
51	1D-H	NMR analysis	0
53	2D	NMR analysis	0
32	C60-SIMS-HMS	C60 SIMS HMS	1
56	CAD	Charged aerosol detector	1
35	Chip_Seq	DNA Sequencing Reads	1
57	DIA-HMS-HCD-CID-MSn	High res MS with HCD-HMSn and DIA-CID-MSn	1
55	DIA-HMS-HCD-HMSn	High res MS with DIA HCD HMSn	1
27	DataFiles	DMS Pipeline Data or Data Packages	0
41	EI-HMS	GC EI coupled with high res MS	1
39	GC	GC with FID, ECD, TCD, etc. (no MS)	1
18	GC-MS	Full scan GC-MS (but not GC QExactive, which is EI-HMS)	1
19	GC-SIM	SIM scan GC-MS	1
1	HMS	High resolution MS spectra only	1
21	HMS-CID/ETD-HMSn	High res MS with high res ETD-based MSn	1
12	HMS-CID/ETD-MSn	High res MS with low res, alternating CID and ETD MSn	1
25	HMS-ETD-HMSn	High res MS with high res ETD-based MSn	1
11	HMS-ETD-MSn	High res MS with low res ETD-based MSn	1
50	HMS-ETciD-EThcD-HMSn	Both ETciD and EThcD, with high res MS1	1
47	HMS-ETciD-EThcD-MSn	Both ETciD and EThcD, with low res MS1	1
49	HMS-ETciD-HMSn	High res MS with ETD fragmentation, then further fragmented by CID in the orbitrap	1
46	HMS-ETciD-MSn	High res MS with ETD fragmentation, then further fragmented by CID in the ion trap	1
48	HMS-EThcD-HMSn	High res MS with ETD fragmentation, then further fragmented by HCD in the orbitrap	1
45	HMS-EThcD-MSn	High res MS with ETD fragmentation, then further fragmented by HCD in the ion routing multipole	1
24	HMS-HCD-CID-HMSn	High res MS with high res HCD MSn and high res CID MSn	1
23	HMS-HCD-CID-MSn	High res MS with high res HCD MSn and low res CID MSn	1
20	HMS-HCD-CID/ETD-HMSn	High res MS with high res HCD MSn and high res CID or ETD MSn (decision tree)	1
14	HMS-HCD-CID/ETD-MSn	High res MS with high res HCD MSn and low res CID or ETD MSn (decision tree)	1
22	HMS-HCD-ETD-HMSn	High res MS with high res HCD MSn and high res ETD MSn	1
15	HMS-HCD-ETD-MSn	High res MS with high res HCD MSn and low res ETD MSn	1
13	HMS-HCD-HMSn	High res MS with high res HCD MSn	1
54	HMS-HCD-MSn	High res MS with low res HCD MSn	1
5	HMS-HMSn	High res MS with high res CID MSn (and possibly some low res MSn)	1
3	HMS-MSn	High res MS with low res CID MSn	1
16	HMS-PQD-CID/ETD-MSn	High res MS with low res PQD MSn and low res CID or ETD MSn (decision tree)	1
17	HMS-PQD-ETD-MSn	High res MS with low res PQD MSn and low res ETD-based MSn	1
6	IMS-HMS	Ion mobility sep then high res MS detection	1
30	IMS-HMS-HMSn	Ion mobility sep with high res MS, fragmentation of all ions with high res MSn	1
7	IMS-HMS-MSn	Ion mobility sep, fragmentation of all ions, high res MS	1
40	LAESI-HMS	LAESI source coupled to a high res MS detector (Orbitrap or 21T)	1
26	MALDI-HMS	MALDI MS	1
9	MRM	Multiple reaction monitoring-triple quad	1
4	MS	Low resolution MS spectra only	1
10	MS-CID/ETD-MSn	Low res MS, with low res, alternating CID and ETD MSn	1
8	MS-ETD-MSn	Low res MS with low res ETD-based MSn	1
28	MS-HCD-CID-MSn	Low res MS with low res, alternating CID and HCD MSn	1
29	MS-HCD-MSn	Low res MS with low res HCD MSn	1
2	MS-MSn	Low res MS with low res CID MSn	1
38	MatePair_mRNA_Seq	DNA Sequencing Reads	1
37	PairedEnd_mRNA_Seq	DNA Sequencing Reads	1
33	SingleRead_mRNA_Seq	DNA Sequencing Reads	0
36	Target_DNA_Seq	DNA Sequencing Reads	1
100	Tracking	Instrument usage tracking only - no capture	1
31	UV	UV detector	1
34	mRNA_Seq	DNA Sequencing Reads	0
42	x_CID-MSn	To be deleted:   Low res CID MSn (no MS1)	0
44	x_ETD-MSn	To be deleted:   Low res ETD-based MSn (no MS1)	0
43	x_HCD-MSn	To be deleted:   Low res HCD MSn (no MS1)	0
\.


--
-- PostgreSQL database dump complete
--

