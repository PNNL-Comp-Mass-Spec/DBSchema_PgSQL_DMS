--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
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
-- Data for Name: t_instrument_group_allowed_ds_type; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_group_allowed_ds_type (instrument_group, dataset_type, comment, dataset_usage_count, dataset_usage_last_year) FROM stdin;
Lumos	HMS-HCD-MSn		8291	1972
QExactive	HMS-HCD-HMSn		120011	22705
Lumos	HMS-HCD-HMSn		28850	2471
QExactive	DIA-HMS-HCD-HMSn		620	184
QEHFX	HMS-HCD-HMSn		33561	5801
Exploris	HMS-HCD-HMSn		7426	6874
Eclipse	HMS-HCD-HMSn		11038	2859
Eclipse	HMS-HCD-MSn		3254	1007
21T	DIA-HMS-HCD-HMSn		67	58
Ascend	DIA-HMS-HCD-HMSn		416	395
Ascend	HMS-HCD-CID-HMSn		0	0
Ascend	HMS-HCD-CID-MSn		52	52
Ascend	HMS-HCD-CID/ETD-HMSn		0	0
Ascend	HMS-HCD-CID/ETD-MSn		0	0
Ascend_Frac	HMS-EThcD-HMSn		0	0
Ascend_Frac	HMS-EThcD-MSn		0	0
Ascend_Frac	HMS-HCD-CID-HMSn		0	0
Ascend_Frac	HMS-HCD-CID-MSn		0	0
Ascend_Frac	HMS-HCD-CID/ETD-HMSn		0	0
Ascend_Frac	HMS-HCD-CID/ETD-MSn		0	0
Ascend_Frac	HMS-HCD-ETD-HMSn		0	0
Ascend_Frac	HMS-HCD-ETD-MSn		0	0
Ascend_Frac	HMS-HCD-HMSn		0	0
Ascend_Frac	HMS-HCD-MSn		0	0
Ascend_Frac	HMS-MSn		0	0
Ascend_Frac	HMS-PQD-CID/ETD-MSn		0	0
Ascend_Frac	HMS-PQD-ETD-MSn		0	0
Ascend_Frac	MS-MSn		0	0
Astral	DIA-HMS-HCD-HMSn		0	0
Astral	HMS		0	0
Astral	HMS-CID/ETD-HMSn		0	0
Astral	HMS-CID/ETD-MSn		0	0
Astral	HMS-ETciD-EThcD-HMSn		0	0
Astral	HMS-ETciD-EThcD-MSn		0	0
Astral	HMS-ETciD-HMSn		0	0
Astral	HMS-ETciD-MSn		0	0
Astral	HMS-ETD-HMSn		0	0
Astral	HMS-ETD-MSn		0	0
Astral	HMS-EThcD-HMSn		0	0
Astral	HMS-EThcD-MSn		0	0
Astral	HMS-HCD-CID-HMSn		0	0
Astral	HMS-HCD-CID-MSn		0	0
Bruker_FTMS	HMS	Typical mode	154595	12118
Astral	HMS-HCD-CID/ETD-HMSn		0	0
Astral	HMS-HCD-CID/ETD-MSn		0	0
Astral	HMS-HCD-ETD-HMSn		0	0
Astral	HMS-HCD-ETD-MSn		0	0
Astral	HMS-HCD-HMSn		110	110
Astral	HMS-HCD-MSn		0	0
Astral	HMS-HMSn		0	0
Astral	HMS-MSn		0	0
Astral	HMS-PQD-CID/ETD-MSn		0	0
Astral	HMS-PQD-ETD-MSn		0	0
Astral	MS-MSn		0	0
Bruker_Amazon_Ion_Trap	MS-CID/ETD-MSn		0	0
Bruker_Amazon_Ion_Trap	MS-ETD-MSn		5	0
Bruker_Amazon_Ion_Trap	MS-MSn		5	0
Bruker_FTMS	C60-SIMS-HMS	Single-scan C60 SIMS	1683	0
Bruker_FTMS	HMS-HMSn		1894	37
Bruker_FTMS	MALDI-HMS	Single-scan MALDI (not imaging)	12483	1925
Bruker_QTOF	HMS		3228	0
Bruker_QTOF	HMS-HMSn		180	0
Bruker_QTOF	MALDI-HMS		0	0
DataFolders	DataFiles		1421	166
Eclipse	DIA-HMS-HCD-HMSn		1102	554
Eclipse	HMS		566	5
Eclipse	HMS-CID/ETD-HMSn		1	0
Eclipse	HMS-CID/ETD-MSn		0	0
Eclipse	HMS-ETciD-EThcD-HMSn		0	0
Eclipse	HMS-ETciD-EThcD-MSn		0	0
Eclipse	HMS-ETciD-HMSn		0	0
Eclipse	HMS-ETciD-MSn		0	0
Eclipse	HMS-ETD-HMSn		31	0
Eclipse	HMS-ETD-MSn		1	0
Eclipse	HMS-EThcD-HMSn		0	0
Eclipse	HMS-EThcD-MSn		0	0
Eclipse	HMS-HCD-CID-HMSn		34	0
Eclipse	HMS-HCD-CID-MSn		205	37
Eclipse	HMS-HCD-CID/ETD-HMSn		0	0
Eclipse	HMS-HCD-CID/ETD-MSn		0	0
Eclipse	HMS-HCD-ETD-HMSn		159	0
Eclipse	HMS-HCD-ETD-MSn		1	0
Eclipse	HMS-HMSn		20	0
Eclipse	HMS-MSn		27	1
Eclipse	HMS-PQD-CID/ETD-MSn		0	0
Eclipse	HMS-PQD-ETD-MSn		0	0
Eclipse	MS-MSn		0	0
Eclipse_Frac	HMS		0	0
Eclipse_Frac	HMS-CID/ETD-HMSn		0	0
Eclipse_Frac	HMS-CID/ETD-MSn		0	0
Eclipse_Frac	HMS-ETciD-EThcD-HMSn		0	0
Eclipse_Frac	HMS-ETciD-EThcD-MSn		0	0
Eclipse_Frac	HMS-ETciD-HMSn		0	0
Eclipse_Frac	HMS-ETciD-MSn		0	0
Eclipse_Frac	HMS-ETD-HMSn		0	0
Eclipse_Frac	HMS-ETD-MSn		0	0
Eclipse_Frac	HMS-EThcD-HMSn		0	0
QExactive-Imaging	MALDI-HMS		450	10
11T	HMS	Typical mode	0	0
11T	HMS-HMSn	Rarely used	0	0
21T	HMS-HMSn		914	0
21T	HMS-MSn	Typical mode	2136	0
21T	MS		2009	108
Eclipse_Frac	HMS-EThcD-MSn		0	0
Eclipse_Frac	HMS-HCD-CID-HMSn		0	0
Eclipse_Frac	HMS-HCD-CID-MSn		0	0
Eclipse_Frac	HMS-HCD-CID/ETD-HMSn		0	0
Eclipse_Frac	HMS-HCD-CID/ETD-MSn		0	0
Eclipse_Frac	HMS-HCD-ETD-HMSn		0	0
Eclipse_Frac	HMS-HCD-ETD-MSn		0	0
Eclipse_Frac	HMS-HCD-HMSn		0	0
Eclipse_Frac	HMS-HCD-MSn		0	0
Eclipse_Frac	HMS-HMSn		0	0
Eclipse_Frac	HMS-MSn		0	0
Eclipse_Frac	HMS-PQD-CID/ETD-MSn		0	0
Eclipse_Frac	HMS-PQD-ETD-MSn		0	0
Eclipse_Frac	MS-MSn		0	0
Exactive	HMS		17040	0
Exploris	DIA-HMS-HCD-HMSn		3008	3008
Exploris	HMS		24	24
Exploris	HMS-HMSn		11	11
Exploris_Frac	HMS		0	0
Exploris_Frac	HMS-HCD-HMSn		0	0
Exploris_Frac	HMS-HMSn		0	0
FT_ZippedSFolders	HMS		19977	0
GC-QExactive	EI-HMS		2691	0
GC-TSQ	GC-MS		0	0
GC-TSQ	MRM	Typical mode	433	0
Illumina	MatePair_mRNA_Seq		0	0
Illumina	PairedEnd_mRNA_Seq		30	0
Illumina	SingleRead_mRNA_Seq		0	0
IMS	IMS-HMS	Typical mode	56627	228
IMS	IMS-HMS-HMSn		28646	1236
IMS	IMS-HMS-MSn		17	0
LCQ	MS		589	0
LCQ	MS-MSn	Typical mode	24438	0
LTQ	MS		842	0
LTQ	MS-MSn	Typical mode	63499	0
LTQ-ETD	MS		304	0
LTQ-FT	HMS-MSn	Typical mode	10163	0
LTQ-FT	MS-MSn		62	0
LTQ-Prep	MS		132	0
LTQ-Prep	MS-MSn	Typical mode	10743	0
Lumos	DIA-HMS-HCD-HMSn		945	604
Lumos	HMS		958	96
Lumos	HMS-CID/ETD-HMSn		71	35
Lumos	HMS-CID/ETD-MSn		3	0
Lumos	HMS-ETciD-EThcD-HMSn		1	0
Lumos	HMS-ETciD-EThcD-MSn		13	0
Lumos	HMS-ETciD-HMSn		51	0
Lumos	HMS-ETciD-MSn		12	0
Lumos	HMS-ETD-HMSn		200	0
Lumos	HMS-ETD-MSn		0	0
Lumos	HMS-EThcD-HMSn		224	0
Lumos	HMS-EThcD-MSn		0	0
Lumos	HMS-HCD-CID-HMSn		605	0
Lumos	HMS-HCD-CID-MSn		12841	8198
Lumos	HMS-HCD-CID/ETD-HMSn		84	0
Lumos	HMS-HCD-CID/ETD-MSn		0	0
Lumos	HMS-HCD-ETD-HMSn		1031	136
Lumos	HMS-HCD-ETD-MSn		0	0
Lumos	HMS-HMSn		781	100
Lumos	HMS-MSn		530	31
Lumos	HMS-PQD-CID/ETD-MSn		0	0
Lumos	HMS-PQD-ETD-MSn		0	0
Lumos	MS-MSn		1	0
Lumos_Frac	HMS		0	0
Lumos_Frac	HMS-CID/ETD-HMSn		0	0
Lumos_Frac	HMS-CID/ETD-MSn		0	0
Lumos_Frac	HMS-ETciD-EThcD-HMSn		0	0
Lumos_Frac	HMS-ETciD-EThcD-MSn		0	0
Lumos_Frac	HMS-ETciD-HMSn		0	0
Lumos_Frac	HMS-ETciD-MSn		0	0
Lumos_Frac	HMS-ETD-HMSn		0	0
Lumos_Frac	HMS-ETD-MSn		0	0
Lumos_Frac	HMS-EThcD-HMSn		0	0
Lumos_Frac	HMS-EThcD-MSn		0	0
Lumos_Frac	HMS-HCD-CID-HMSn		0	0
Lumos_Frac	HMS-HCD-CID-MSn		0	0
Lumos_Frac	HMS-HCD-CID/ETD-HMSn		0	0
Lumos_Frac	HMS-HCD-CID/ETD-MSn		0	0
Lumos_Frac	HMS-HCD-ETD-HMSn		0	0
Lumos_Frac	HMS-HCD-ETD-MSn		0	0
Lumos_Frac	HMS-HCD-HMSn		0	0
Lumos_Frac	HMS-HCD-MSn		0	0
Lumos_Frac	HMS-HMSn		0	0
Lumos_Frac	HMS-MSn		0	0
Lumos_Frac	HMS-PQD-CID/ETD-MSn		0	0
Lumos_Frac	HMS-PQD-ETD-MSn		0	0
Lumos_Frac	MS-MSn		0	0
MALDI-Imaging	C60-SIMS-HMS	Imaging datasets using C60 SIMS	52	0
MALDI-TOF	MALDI-HMS		359	0
NMR	1D-C		0	0
NMR	1D-H		0	0
NMR	2D		0	0
Orbitrap	HMS		7227	0
Orbitrap	HMS-HMSn		2863	0
Orbitrap	HMS-MSn	Typical mode	66374	0
Orbitrap	MS-MSn		244	0
Other	HMS-HCD-HMSn		258	0
Other	HMS-HMSn		509	0
Other	HMS-MSn		0	0
Other	MS		0	0
Other	MS-MSn		0	0
PrepHPLC	UV		73	71
QEHFX	DIA-HMS-HCD-HMSn		334	330
QEHFX	HMS		227	6
QEHFX	HMS-HMSn		0	0
QEHFX_Frac	HMS		0	0
QEHFX_Frac	HMS-HCD-HMSn		0	0
QEHFX_Frac	HMS-HMSn		0	0
QExactive	HMS		26473	6438
QExactive	HMS-HMSn		15	0
QExactive-Imaging	HMS		66	41
QExactive-Imaging	HMS-HCD-HMSn		10	9
QExactive-Imaging	HMS-HMSn		0	0
QExactive_Frac	HMS		0	0
QExactive_Frac	HMS-HCD-HMSn		0	0
QExactive_Frac	HMS-HMSn		0	0
QTrap	MRM		3899	0
QTrap	MS		0	0
QTrap	MS-MSn	Typical mode	0	0
MALDI-Imaging	MALDI-HMS	Typical mode	2153	233
21T	HMS		23842	1263
21T	MS-MSn		20	0
5500XL_SOLiD	Chip_Seq		0	0
5500XL_SOLiD	MatePair_mRNA_Seq		0	0
5500XL_SOLiD	PairedEnd_mRNA_Seq		0	0
5500XL_SOLiD	SingleRead_mRNA_Seq		0	0
5500XL_SOLiD	Target_DNA_Seq		0	0
5500XL_SOLiD	Tracking		0	0
Agilent_FTMS	HMS		0	0
Agilent_GC	GC		0	0
Agilent_GC-MS	GC-SIM		0	0
Agilent_Ion_Trap	MS		0	0
Agilent_Ion_Trap	MS-MSn		710	0
Agilent_QQQ	HMS-HMSn		190	0
Agilent_QQQ	MRM		2562	0
Agilent_TOF	HMS		1543	0
Agilent_TOF_V2	HMS		418	29
Agilent_TOF_V2	HMS-HMSn	Typical mode	397	0
Agilent_TOF_V2	MS	\N	0	0
Altis	MRM		0	0
Ascend	HMS		7	7
Ascend	HMS-CID/ETD-HMSn		0	0
Ascend	HMS-CID/ETD-MSn		0	0
Ascend	HMS-ETciD-EThcD-HMSn		0	0
Ascend	HMS-ETciD-EThcD-MSn		0	0
Ascend	HMS-ETciD-HMSn		0	0
Ascend	HMS-ETciD-MSn		0	0
Ascend	HMS-ETD-HMSn		0	0
Ascend	HMS-ETD-MSn		0	0
Ascend	HMS-EThcD-HMSn		0	0
Ascend	HMS-EThcD-MSn		0	0
Ascend	HMS-HCD-ETD-HMSn		8	0
Ascend	HMS-HCD-ETD-MSn		0	0
Ascend	HMS-HCD-MSn		26	16
Ascend	HMS-HMSn		0	0
Ascend	HMS-MSn		0	0
Ascend	HMS-PQD-CID/ETD-MSn		0	0
Ascend	HMS-PQD-ETD-MSn		0	0
Ascend	MS-MSn		0	0
Ascend_Frac	HMS		0	0
Ascend_Frac	HMS-CID/ETD-HMSn		0	0
Ascend_Frac	HMS-CID/ETD-MSn		0	0
Ascend_Frac	HMS-ETciD-EThcD-HMSn		0	0
Ascend_Frac	HMS-ETciD-EThcD-MSn		0	0
Ascend_Frac	HMS-ETciD-HMSn		0	0
Sciex_TripleTOF	HMS-HMSn		26	0
Shimadzu_GC	GC-MS		326	0
SLIM	IMS-HMS	\N	6060	0
SLIM	IMS-HMS-HMSn	\N	0	0
SLIM	IMS-HMS-MSn	\N	0	0
Thermo_SII_LC	CAD		158	158
Thermo_SII_LC	UV		0	0
timsTOF	IMS-HMS		0	0
timsTOF	IMS-HMS-HMSn		2367	2325
TSQ	MS		166	0
TSQ	MS-MSn	Use for MSn	2935	0
TSQ_Frac	MRM		0	0
TSQ_Frac	MS		0	0
TSQ_Frac	MS-MSn		0	0
VelosOrbi	HMS		11870	1034
VelosOrbi	HMS-CID/ETD-HMSn		195	0
VelosOrbi	HMS-CID/ETD-MSn		932	0
VelosOrbi	HMS-ETD-HMSn		911	0
VelosOrbi	HMS-ETD-MSn		128	0
VelosOrbi	HMS-HCD-CID-HMSn		1920	0
VelosOrbi	HMS-HCD-CID-MSn		60225	3243
VelosOrbi	HMS-HCD-CID/ETD-HMSn		37	0
VelosOrbi	HMS-HCD-CID/ETD-MSn		1099	0
VelosOrbi	HMS-HCD-ETD-HMSn		335	0
VelosOrbi	HMS-HCD-ETD-MSn		216	0
VelosOrbi	HMS-HCD-HMSn		28711	0
VelosOrbi	HMS-HCD-MSn		130	16
VelosOrbi	HMS-HMSn		3015	8
VelosOrbi	HMS-MSn		66463	22
VelosOrbi	HMS-PQD-CID/ETD-MSn		35	0
VelosOrbi	HMS-PQD-ETD-MSn		0	0
Agilent_QQQ	HMS		2650	42
Agilent_GC-MS	GC-MS		50764	2688
Ascend	HMS-HCD-HMSn		1653	1301
TSQ	MRM	Use for MRM	146592	8965
Ascend_Frac	HMS-ETciD-MSn		0	0
Ascend_Frac	HMS-ETD-HMSn		0	0
Ascend_Frac	HMS-ETD-MSn		0	0
Ascend_Frac	HMS-HMSn		0	0
LTQ-ETD	MS-CID/ETD-MSn		355	0
LTQ-ETD	MS-ETD-MSn		491	0
LTQ-ETD	MS-MSn		3363	0
LTQ-FT	HMS		1030	0
LTQ-FT	HMS-HMSn		94	0
Waters_TOF	HMS		1510	61
VelosOrbi	LAESI-HMS	LAESI source coupled to an Orbitrap; results are in folders with a .raw file plus related files	2	0
VelosOrbi	MS-MSn		177	0
VelosPro	MS		10	0
VelosPro	MS-CID/ETD-MSn		0	0
VelosPro	MS-ETD-MSn		0	0
VelosPro	MS-HCD-CID-MSn		7	0
VelosPro	MS-HCD-MSn		0	0
VelosPro	MS-MSn		4461	0
Waters_IMS	HMS		8834	329
Waters_IMS	HMS-HMSn		719	0
Waters_IMS	IMS-HMS		1559	0
Waters_IMS	IMS-HMS-HMSn		241	0
Waters_IMS	IMS-HMS-MSn		0	0
Waters_TOF	HMS-HMSn		32	0
\.


--
-- PostgreSQL database dump complete
--

