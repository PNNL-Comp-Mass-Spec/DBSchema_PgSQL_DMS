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
-- Data for Name: t_param_file_types; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_param_file_types (param_file_type_id, param_file_type, primary_tool_id) FROM stdin;
1	(none)	0
1005	AgilentTOFPek	11
1014	DTA_Gen	22
1002	DeNovoPeak	8
1010	Decon2LS	16
1035	DiaNN	92
1030	Formularity	81
1036	FragPipe	93
1024	GlyQ-IQ	66
1012	Inspect	20
1006	LTQ_FTPek	12
1021	LipidMapSearch	51
1007	MASIC	13
1004	MLynxPek	10
1028	MODPlus	73
1023	MODa	64
1019	MSAlign	38
1022	MSAlign_Histone	59
1015	MSClusterDAT_Gen	0
1033	MSFragger	88
1018	MSGFPlus	36
1025	MSPathFinder	67
1013	MSXML_Gen	21
1034	MaxQuant	91
1017	MultiAlign	35
1027	NOMSI	72
1016	OMSSA	28
1026	ProMex	70
1029	QC-ART	75
1001	QTOFPek	7
1020	SMAQC	41
1000	Sequest	1
1011	TIC_D2L	17
1031	TopFD	82
1032	TopPIC	83
1008	XTandem	15
1003	icr2ls	2
\.


--
-- PostgreSQL database dump complete
--

