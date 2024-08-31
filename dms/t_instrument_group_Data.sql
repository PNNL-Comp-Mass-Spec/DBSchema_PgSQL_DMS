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
-- Data for Name: t_instrument_group; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_group (instrument_group, usage, comment, active, default_dataset_type, allocation_tag, sample_prep_visible, requested_run_visible, target_instrument_group) FROM stdin;
11T	Research		0	1	\N	0	1	\N
21T	Research		1	1	FT	1	1	\N
5500XL_SOLiD	Genomic Sequencing	\N	0	33	SEQ	0	0	\N
Agilent_FTMS	Research		0	1	FT	0	1	\N
Agilent_GC	Research		0	39	GC	0	1	\N
Agilent_GC_MS	Metabolomics		1	18	GC	1	1	\N
Agilent_Ion_Trap	Research		0	2	\N	0	1	\N
Agilent_QQQ	MRM		1	9	QQQ	1	1	\N
Agilent_TOF	Research		0	1	\N	0	1	\N
Agilent_TOF_V2	Research		1	3	TOF	0	0	\N
Altis	MRM		0	9	QQQ	0	0	\N
Ascend	LC-HMS with MS/MS		1	13	ORB	1	1	\N
Ascend_Frac	Requested runs with LC-MicroHpH, LC-MicroSCX, LC-NanoHpH, etc.		1	13	ORB	0	1	Ascend
Astral	LC-HMS with MS/MS		1	13	ORB	1	1	\N
Bruker_Amazon_Ion_Trap	Research		0	3	\N	0	1	\N
Bruker_FTMS	Research		1	1	FT	1	1	\N
Bruker_QTOF	Research		0	5	TOF	0	0	\N
DataFolders	DMS Pipeline Data		0	27	\N	0	1	\N
Eclipse	LC-HMS with MS/MS		1	13	ORB	1	1	\N
Eclipse_Frac	Requested runs with LC-MicroHpH, LC-MicroSCX, LC-NanoHpH, etc.		1	13	ORB	0	1	Eclipse
Exactive	LC-HMS (no MS/MS)		0	1	EXA	1	1	\N
Exploris	LC-HMS with MS/MS; optionally HCD		1	5	ORB	1	1	\N
Exploris_Frac	Requested runs with LC-MicroHpH, LC-MicroSCX, LC-NanoHpH, etc.		1	5	ORB	0	1	Exploris
FT_ZippedSFolders	Research		0	1	\N	0	1	\N
GC_QExactive	Metabolomics	\N	1	41	ORB	1	1	\N
GC_TSQ	Metabolomics		0	9	GC	0	0	\N
IMS	Ion-mobility LC-IMS-MS		1	6	IMS	1	1	\N
Illumina	Genomic Sequencing	\N	0	33	SEQ	1	0	\N
LCMSNet_LC	LCMSNet LCs with no available LC pump data file	If there is a Thermo pump on the LC controlled with SII for Xcalibur, use Thermo_SII_LC instead	1	31	None	0	0	\N
LCQ	Low res MS/MS		0	2	\N	0	1	\N
LTQ	Low res MS/MS		1	2	LTQ	0	0	\N
LTQ_ETD	Low res MS/MS ETD		0	2	LTQ	0	0	\N
LTQ_FT	LC-HMS with MS/MS		0	3	FT	0	1	\N
LTQ_Prep	LTQ in BSF sample prep lab		0	2	LTQ	1	0	\N
Lumos	LC-HMS with MS/MS; optionally ETD		1	5	ORB	1	1	\N
Lumos_Frac	Requested runs with LC-MicroHpH, LC-MicroSCX, LC-NanoHpH, etc.		1	5	ORB	0	1	Lumos
MALDI_Imaging	MALDI Imaging		1	26	MAL	1	1	\N
MALDI_TOF	MALDI Spot	\N	0	26	MAL	0	1	\N
MALDI_timsTOF_Imaging	MALDI Imaging on timsTOF Flex		1	26	MAL	1	1	\N
NMR	Research	For use in sample prep requests	1	51	NMR	1	0	\N
Orbitrap	LC-HMS with MS/MS		0	3	ORB	1	0	\N
Other	Research		1	\N	None	0	1	\N
PrepHPLC	Prep HPLC Data folders		1	31	None	0	0	\N
QEHFX	LC-HMS with MS/MS; optionally HCD		1	5	ORB	1	1	\N
QEHFX_Frac	Requested runs with LC-MicroHpH, LC-MicroSCX, LC-NanoHpH, etc.		1	5	ORB	0	1	QEHFX
QExactive	LC-HMS with MS/MS; optionally HCD	Was originally used by LTQ_Orb_3, but changed LTQ_Orb_3 to the "Orbitrap" group in May 2012.  Renamed this group from Orbitrap-HCD to QExactive in December 2012	1	5	ORB	1	1	\N
QExactive_Frac	Requested runs with LC-MicroHpH, LC-MicroSCX, LC-NanoHpH, etc.		1	5	ORB	0	1	QExactive
QExactive_Imaging	QExactive with MALDI source		1	5	ORB	0	0	\N
QTrap	Research	MRM	0	3	QQQ	0	1	\N
SLIM	Ion-mobility LC-IMS-MS with SLIM		1	6	IMS	1	1	\N
Sciex_TripleTOF	Research		0	5	\N	0	0	\N
Shimadzu_GC	Real-time atmospheric monitoring		1	18	GC	0	1	\N
TSQ	MRM		1	9	QQQ	1	1	\N
TSQ_Frac	Requested runs with LC-MicroHpH, LC-MicroSCX, LC-NanoHpH, etc.		1	9	QQQ	0	1	TSQ
Thermo_SII_LC	LC instruments controlled using SII for Xcalibur	SII - Standard Instrument Integration, allows controlling Chromeleon-supported LC modules from Xcalibur	1	31	None	0	0	\N
VelosOrbi	LC-HMS with MS/MS; optionally ETD		1	3	ORB	1	1	\N
VelosPro	Ion trap instrument with CID, HCD, PQD, or ETD; No orbitrap		0	2	LTQ	0	1	\N
Waters_Acquity_LC	Waters Acquity LC instruments controlled using MassLynx		1	31	None	0	0	\N
Waters_IMS	Waters Synapt IMS		1	6	IMS	1	1	\N
Waters_TOF	Research		1	1	TOF	0	1	\N
timsTOF	LC-IMS-MS with MS/MS	Bruker timsTOF	0	30	TOF	0	0	\N
timsTOF_Flex	LC-IMS-MS with MS/MS	Bruker timsTOF Flex	1	30	TOF	1	1	\N
timsTOF_SCP	LC-IMS-MS with MS/MS	Bruker timsTOF SCP	1	30	TOF	1	1	\N
\.


--
-- PostgreSQL database dump complete
--

