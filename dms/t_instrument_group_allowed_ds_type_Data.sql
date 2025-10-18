--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
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
-- Data for Name: t_instrument_group_allowed_ds_type; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_group_allowed_ds_type (instrument_group, dataset_type, comment, dataset_usage_count, dataset_usage_last_year) FROM stdin;
11T	HMS	Typical mode	0	0
11T	HMS-HMSn	Rarely used	0	0
21T	DIA-HMS-HCD-HMSn		76	6
21T	HMS		24154	135
21T	HMS-HMSn		914	0
21T	HMS-MSn	Typical mode	2136	0
21T	MS		2054	1
21T	MS-MSn		20	0
5500XL_SOLiD	Chip_Seq		0	0
5500XL_SOLiD	MatePair_mRNA_Seq		0	0
5500XL_SOLiD	PairedEnd_mRNA_Seq		0	0
5500XL_SOLiD	SingleRead_mRNA_Seq		0	0
5500XL_SOLiD	Target_DNA_Seq		0	0
5500XL_SOLiD	Tracking		0	0
Agilent_FTMS	HMS		0	0
Agilent_GC	GC		0	0
Agilent_GC_MS	GC-MS		52814	1236
Agilent_GC_MS	GC-SIM		0	0
Agilent_Ion_Trap	MS		0	0
Agilent_Ion_Trap	MS-MSn		710	0
Agilent_QQQ	HMS		2650	0
Agilent_QQQ	HMS-HMSn		190	0
Agilent_QQQ	MRM		2562	0
Agilent_TOF	HMS		1543	0
Agilent_TOF_V2	HMS		489	71
Agilent_TOF_V2	HMS-HMSn	Typical mode	397	0
Agilent_TOF_V2	MS	\N	0	0
Altis	MRM		0	0
Ascend	DIA-HMS-HCD-HMSn		1375	701
Ascend	HMS		15	4
Ascend	HMS-CID/ETD-HMSn		0	0
Ascend	HMS-CID/ETD-MSn		0	0
Ascend	HMS-ETD-HMSn		0	0
Ascend	HMS-ETD-MSn		0	0
Ascend	HMS-ETciD-EThcD-HMSn		0	0
Ascend	HMS-ETciD-EThcD-MSn		0	0
Ascend	HMS-ETciD-HMSn		0	0
Ascend	HMS-ETciD-MSn		0	0
Ascend	HMS-EThcD-HMSn		0	0
Ascend	HMS-EThcD-MSn		0	0
Ascend	HMS-HCD-CID-HMSn		0	0
Ascend	HMS-HCD-CID-MSn		83	0
Ascend	HMS-HCD-CID/ETD-HMSn		0	0
Ascend	HMS-HCD-CID/ETD-MSn		0	0
Ascend	HMS-HCD-ETD-HMSn		8	0
Ascend	HMS-HCD-ETD-MSn		0	0
Ascend	HMS-HCD-HMSn		3466	1530
Ascend	HMS-HCD-MSn		52	0
Ascend	HMS-HMSn		0	0
Ascend	HMS-MSn		0	0
Ascend	HMS-PQD-CID/ETD-MSn		0	0
Ascend	HMS-PQD-ETD-MSn		0	0
Ascend	MS-MSn		0	0
Ascend_Frac	HMS		0	0
Ascend_Frac	HMS-CID/ETD-HMSn		0	0
Ascend_Frac	HMS-CID/ETD-MSn		0	0
Ascend_Frac	HMS-ETD-HMSn		0	0
Ascend_Frac	HMS-ETD-MSn		0	0
Ascend_Frac	HMS-ETciD-EThcD-HMSn		0	0
Ascend_Frac	HMS-ETciD-EThcD-MSn		0	0
Ascend_Frac	HMS-ETciD-HMSn		0	0
Ascend_Frac	HMS-ETciD-MSn		0	0
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
Ascend_Frac	HMS-HMSn		0	0
Ascend_Frac	HMS-MSn		0	0
Ascend_Frac	HMS-PQD-CID/ETD-MSn		0	0
Ascend_Frac	HMS-PQD-ETD-MSn		0	0
Ascend_Frac	MS-MSn		0	0
Astral	DIA-HMS-HCD-HMSn		7782	6939
Astral	HMS		22	22
Astral	HMS-CID/ETD-HMSn		0	0
Astral	HMS-CID/ETD-MSn		0	0
Astral	HMS-ETD-HMSn		0	0
Astral	HMS-ETD-MSn		0	0
Astral	HMS-ETciD-EThcD-HMSn		0	0
Astral	HMS-ETciD-EThcD-MSn		0	0
Astral	HMS-ETciD-HMSn		0	0
Astral	HMS-ETciD-MSn		0	0
Astral	HMS-EThcD-HMSn		0	0
Astral	HMS-EThcD-MSn		0	0
Astral	HMS-HCD-CID-HMSn		0	0
Astral	HMS-HCD-CID-MSn		0	0
Astral	HMS-HCD-CID/ETD-HMSn		0	0
Astral	HMS-HCD-CID/ETD-MSn		0	0
Astral	HMS-HCD-ETD-HMSn		0	0
Astral	HMS-HCD-ETD-MSn		0	0
Astral	HMS-HCD-HMSn		415	280
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
Bruker_FTMS	HMS	Typical mode	170075	12355
Bruker_FTMS	HMS-HMSn		1898	4
Bruker_FTMS	MALDI-HMS	Single-scan MALDI (not imaging)	13319	770
Bruker_QTOF	HMS		3228	0
Bruker_QTOF	HMS-HMSn		180	0
Bruker_QTOF	MALDI-HMS		0	0
DataFolders	DataFiles		1652	197
Eclipse	DIA-HMS-HCD-HMSn		1345	243
Eclipse	HMS		795	227
Eclipse	HMS-CID/ETD-HMSn		1	0
Eclipse	HMS-CID/ETD-MSn		0	0
Eclipse	HMS-ETD-HMSn		31	0
Eclipse	HMS-ETD-MSn		1	0
Eclipse	HMS-ETciD-EThcD-HMSn		0	0
Eclipse	HMS-ETciD-EThcD-MSn		0	0
Eclipse	HMS-ETciD-HMSn		0	0
Eclipse	HMS-ETciD-MSn		0	0
Eclipse	HMS-EThcD-HMSn		0	0
Eclipse	HMS-EThcD-MSn		0	0
Eclipse	HMS-HCD-CID-HMSn		148	114
Eclipse	HMS-HCD-CID-MSn		2345	2140
Eclipse	HMS-HCD-CID/ETD-HMSn		0	0
Eclipse	HMS-HCD-CID/ETD-MSn		0	0
Eclipse	HMS-HCD-ETD-HMSn		159	0
Eclipse	HMS-HCD-ETD-MSn		1	0
Eclipse	HMS-HCD-HMSn		13892	2130
Eclipse	HMS-HCD-MSn		5135	728
Eclipse	HMS-HMSn		20	0
Eclipse	HMS-MSn		71	44
Eclipse	HMS-PQD-CID/ETD-MSn		0	0
Eclipse	HMS-PQD-ETD-MSn		0	0
Eclipse	MS-MSn		0	0
Eclipse_Frac	HMS		0	0
Eclipse_Frac	HMS-CID/ETD-HMSn		0	0
Eclipse_Frac	HMS-CID/ETD-MSn		0	0
Eclipse_Frac	HMS-ETD-HMSn		0	0
Eclipse_Frac	HMS-ETD-MSn		0	0
Eclipse_Frac	HMS-ETciD-EThcD-HMSn		0	0
Eclipse_Frac	HMS-ETciD-EThcD-MSn		0	0
Eclipse_Frac	HMS-ETciD-HMSn		0	0
Eclipse_Frac	HMS-ETciD-MSn		0	0
Eclipse_Frac	HMS-EThcD-HMSn		0	0
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
Exploris	DIA-HMS-HCD-HMSn		11260	6770
Exploris	HMS		1201	1177
Exploris	HMS-HCD-HMSn		21776	11864
Exploris	HMS-HMSn		12	1
Exploris_Frac	HMS		0	0
Exploris_Frac	HMS-HCD-HMSn		0	0
Exploris_Frac	HMS-HMSn		0	0
FT_ZippedSFolders	HMS		19977	0
GC_QExactive	EI-HMS		2691	0
GC_TSQ	GC-MS		0	0
GC_TSQ	MRM	Typical mode	433	0
IMS	IMS-HMS	Typical mode	56808	181
IMS	IMS-HMS-HMSn		29085	439
IMS	IMS-HMS-MSn		17	0
IQX	HMS		0	0
IQX	HMS-HCD-CID-HMSn		0	0
IQX	HMS-HCD-CID-MSn		82	82
IQX	HMS-HCD-HMSn		1	1
IQX	HMS-HCD-MSn		0	0
IQX	HMS-HMSn		0	0
IQX	HMS-MSn		0	0
IQX	MS-MSn		0	0
Illumina	MatePair_mRNA_Seq		0	0
Illumina	PairedEnd_mRNA_Seq		30	0
Illumina	SingleRead_mRNA_Seq		0	0
LCQ	MS		589	0
LCQ	MS-MSn	Typical mode	24438	0
LTQ	MS		842	0
LTQ	MS-MSn	Typical mode	63499	0
LTQ_ETD	MS		304	0
LTQ_ETD	MS-CID/ETD-MSn		355	0
LTQ_ETD	MS-ETD-MSn		491	0
LTQ_ETD	MS-MSn		3363	0
LTQ_FT	HMS		1030	0
LTQ_FT	HMS-HMSn		94	0
LTQ_FT	HMS-MSn	Typical mode	10163	0
LTQ_FT	MS-MSn		62	0
LTQ_Prep	MS		132	0
LTQ_Prep	MS-MSn	Typical mode	10743	0
Lumos	DIA-HMS-HCD-HMSn		998	53
Lumos	HMS		1230	215
Lumos	HMS-CID/ETD-HMSn		74	0
Lumos	HMS-CID/ETD-MSn		3	0
Lumos	HMS-ETD-HMSn		200	0
Lumos	HMS-ETD-MSn		0	0
Lumos	HMS-ETciD-EThcD-HMSn		1	0
Lumos	HMS-ETciD-EThcD-MSn		13	0
Lumos	HMS-ETciD-HMSn		51	0
Lumos	HMS-ETciD-MSn		12	0
Lumos	HMS-EThcD-HMSn		224	0
Lumos	HMS-EThcD-MSn		0	0
Lumos	HMS-HCD-CID-HMSn		830	167
Lumos	HMS-HCD-CID-MSn		30058	12278
Lumos	HMS-HCD-CID/ETD-HMSn		84	0
Lumos	HMS-HCD-CID/ETD-MSn		0	0
Lumos	HMS-HCD-ETD-HMSn		1033	1
Lumos	HMS-HCD-ETD-MSn		0	0
Lumos	HMS-HCD-HMSn		29790	833
Lumos	HMS-HCD-MSn		10873	2117
Lumos	HMS-HMSn		933	82
Lumos	HMS-MSn		530	0
Lumos	HMS-PQD-CID/ETD-MSn		0	0
Lumos	HMS-PQD-ETD-MSn		0	0
Lumos	MS-MSn		1	0
Lumos_Frac	HMS		0	0
Lumos_Frac	HMS-CID/ETD-HMSn		0	0
Lumos_Frac	HMS-CID/ETD-MSn		0	0
Lumos_Frac	HMS-ETD-HMSn		0	0
Lumos_Frac	HMS-ETD-MSn		0	0
Lumos_Frac	HMS-ETciD-EThcD-HMSn		0	0
Lumos_Frac	HMS-ETciD-EThcD-MSn		0	0
Lumos_Frac	HMS-ETciD-HMSn		0	0
Lumos_Frac	HMS-ETciD-MSn		0	0
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
MALDI_Imaging	C60-SIMS-HMS	Imaging datasets using C60 SIMS	52	0
MALDI_Imaging	MALDI-HMS	Typical mode	2322	135
MALDI_TOF	MALDI-HMS		359	0
MALDI_timsTOF_Imaging	MALDI-HMS		307	266
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
PrepHPLC	UV		73	0
QEHFX	DIA-HMS-HCD-HMSn		671	309
QEHFX	HMS		242	14
QEHFX	HMS-HCD-HMSn		39407	4375
QEHFX	HMS-HMSn		0	0
QEHFX_Frac	HMS		0	0
QEHFX_Frac	HMS-HCD-HMSn		0	0
QEHFX_Frac	HMS-HMSn		0	0
QExactive	DIA-HMS-HCD-HMSn		627	7
QExactive	HMS		32632	1372
QExactive	HMS-HCD-HMSn		148804	22305
QExactive	HMS-HMSn		15	0
QExactive_Frac	HMS		0	0
QExactive_Frac	HMS-HCD-HMSn		0	0
QExactive_Frac	HMS-HMSn		0	0
QExactive_Imaging	HMS		103	37
QExactive_Imaging	HMS-HCD-HMSn		10	0
QExactive_Imaging	HMS-HMSn		0	0
QExactive_Imaging	MALDI-HMS		472	5
QTrap	MRM		3899	0
QTrap	MS		0	0
QTrap	MS-MSn	Typical mode	0	0
SLIM	IMS-HMS	\N	6060	0
SLIM	IMS-HMS-HMSn	\N	0	0
SLIM	IMS-HMS-MSn	\N	0	0
Sciex_TripleTOF	HMS-HMSn		26	0
Shimadzu_GC	GC-MS		326	0
TSQ	MRM	Use for MRM	165343	16724
TSQ	MS		166	0
TSQ	MS-MSn	Use for MSn	2935	0
TSQ_Frac	MRM		0	0
TSQ_Frac	MS		0	0
TSQ_Frac	MS-MSn		0	0
Thermo_SII_LC	CAD		158	0
Thermo_SII_LC	UV		0	0
VelosOrbi	HMS		12085	148
VelosOrbi	HMS-CID/ETD-HMSn		195	0
VelosOrbi	HMS-CID/ETD-MSn		932	0
VelosOrbi	HMS-ETD-HMSn		911	0
VelosOrbi	HMS-ETD-MSn		128	0
VelosOrbi	HMS-HCD-CID-HMSn		1920	0
VelosOrbi	HMS-HCD-CID-MSn		60225	0
VelosOrbi	HMS-HCD-CID/ETD-HMSn		37	0
VelosOrbi	HMS-HCD-CID/ETD-MSn		1099	0
VelosOrbi	HMS-HCD-ETD-HMSn		335	0
VelosOrbi	HMS-HCD-ETD-MSn		216	0
VelosOrbi	HMS-HCD-HMSn		28711	0
VelosOrbi	HMS-HCD-MSn		130	0
VelosOrbi	HMS-HMSn		3024	0
VelosOrbi	HMS-MSn		66473	0
VelosOrbi	HMS-PQD-CID/ETD-MSn		35	0
VelosOrbi	HMS-PQD-ETD-MSn		0	0
VelosOrbi	LAESI-HMS	LAESI source coupled to an Orbitrap; results are in folders with a .raw file plus related files	2	0
VelosOrbi	MS-MSn		177	0
VelosPro	MS		10	0
VelosPro	MS-CID/ETD-MSn		0	0
VelosPro	MS-ETD-MSn		0	0
VelosPro	MS-HCD-CID-MSn		7	0
VelosPro	MS-HCD-MSn		0	0
VelosPro	MS-MSn		4461	0
Waters_IMS	HMS		8880	40
Waters_IMS	HMS-HMSn		719	0
Waters_IMS	IMS-HMS		1559	0
Waters_IMS	IMS-HMS-HMSn		241	0
Waters_IMS	IMS-HMS-MSn		0	0
Waters_TOF	HMS		1510	0
Waters_TOF	HMS-HMSn		32	0
timsTOF	IMS-HMS		0	0
timsTOF	IMS-HMS-HMSn		42	0
timsTOF_Flex	IMS-HMS		0	0
timsTOF_Flex	IMS-HMS-HMSn		12	1
timsTOF_SCP	IMS-HMS		0	0
timsTOF_SCP	IMS-HMS-HMSn		3762	1238
\.


--
-- PostgreSQL database dump complete
--

