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
-- Data for Name: t_prep_lc_column; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_prep_lc_column (prep_column_id, prep_column, mfg_name, mfg_model, mfg_serial, packing_mfg, packing_type, particle_size, particle_type, column_inner_dia, column_outer_dia, length, state, operator_username, comment, created) FROM stdin;
1002	Mouse_SMix_01	Seppro IgY-M-Supermix-LC5	28-288-23364-LC5	\N	Genway	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Active	D3M765	Received July 9, 2008. Weijun's old mouse supermix column.	2009-08-19 08:36:03
1003	Mouse_M7_01	Seppro IgY-M7 LC10	28-288-12007-LC10	\N	Genway	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Weijun's old M7 column. 2 test runs on 6/12/12. The column is not binding as efficiently as it should. Column is retired and should not be used.	2009-08-19 08:37:43
1004	SCX-200-04	Poly LC PolysulfoethylA	202SE0503	J2466B	Poly LC	SCX	5 um	300-A	N/A	2.1mm	200mm	Retired	D3M765	Column is for mammalian samples only!,,Samples run prior to DMS: 170, , Retired by MG on 06/02/2014 after performance testing.	2009-08-19 08:42:37
1005	SCX-200-05	Poly LC PolysulfoethylA	202SE0503	J2467E	Poly LC	SCX	5 um	300-A	N/A	2.1mm	200mm	Retired	D3M765	This column is for human plasma samples only! Put in use 10/8/07.,,Samples run prior to DMS: 12. Column sent to Broad, SCX-200-08 sent to PNNL as replacement.	2009-08-19 08:44:28
1006	SCX-200-06	Poly LC  PolysulfoethylA	P202SE0503	C0582A	Poly LC	SCX	5 um	300-A	N/A	2.1mm	200mm	Retired	D3M765	General use column. Received 6/1/08, put in use 6/24/08.,,Samples run prior to DMS: 190	2009-08-19 08:46:25
1007	SCX-35-01	Poly LC PolysulfoethylA	3.52SE0303	I1362	Poly LC	SCX	3 um	300-A	N/A	2.1mm	35mm	Retired	D3M765	General use. Put in use 5/1/07.,,Samples run prior to DMS: 200	2009-08-19 08:48:27
1008	SCX-35-02	Poly LC PolysulfoethylA	3.52SE0303	H1571	Poly LC	SCX	3 um	300-A	N/A	2.1mm	35mm	Retired	D3M765	Column is for human and mammalian samples only! Put in use 10/15/07.,,Samples run prior to DMS: 129	2009-08-19 08:49:07
1009	Mouse_M7_02	Seppro Mouse LC10	S5699-1EA	128K0503	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Active	D3M765	Weijun's new M7 column. 5/19/09	2009-08-20 08:14:59
1010	Mouse_SMix_02	Seppro Supermix Mouse LC5	S5824-1EA	128K0517	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Active	D3M765	Received 5/19/09. Weijun's new mouse supermix column.	2009-08-20 08:15:49
1011	Human_IgY14_LC10_01	Seppro IgY14 LC10	S5074-1EA	128K0506	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Weijun's new IgY14 LC10 column. 6/23/09	2009-08-20 08:17:54
1012	Human_Supermix_01	Seppro Supermix LC5	S5324-1EA	128K0505	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Weijun's new Supermix column. 5/20/09	2009-08-20 08:18:38
1013	IgY12_LC10_01	IgY12 LC10 Column	A24355	060328022	ProteomeLab	Ig antibodies	Unk	Ig antibodies	n/a	n/a	n/a	Retired	d3m765	Received 2006. Expires 3/28/08. History of 282 runs prior to entry in DMS.	2009-08-28 08:14:42
1014	Human_Supermix_02	Seppro Supermix LC5	28-288-23078-LC5	LN081222	Genway	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Active	D3M765	Tom Metz's old Supermix column. 12/22/08. 73 runs on it previously.	2009-09-02 12:30:05
1015	SEC200_01	Superdex 200 10/300 GL	17-5175-01	10017633	GE Healthcare	SEC particles	unknown	SEC	n/a	n/a	n/a	Active	d3m765	Tao's SEC. Expires 11/2012. Put in use 6/2008. 13 runs previously.	2009-09-04 09:14:14
1016	SEC200_02	Superdex 200 10/300 GL	17-5175-01	10022088/0810086	GE Healthcare	SEC particles	unknown	SEC	n/a	n/a	n/a	Retired	d3m765	Femg's SEC. Expires 1/2013. Tao used on 9/9/09 with BSL2 samples	2009-09-11 08:00:34
1017	Human_Supermix_03	Seppro Supermix LC5	S5324-1EA	0796036	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's new Supermix column for EIF. 9/19/09	2009-09-17 11:48:17
1018	Human_IgY14_LC10_03	Seppro IgY14 LC10	S5074-1EA	089K6100	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's new IgY14 LC10 column for EIF. 9/17/09	2009-09-17 11:52:31
1019	SCX-200-07	Poly LC  PolysulfoethylA	P202SE0503	I0292D	Poly LC	SCX	5 um	300-A	N/A	2.1mm	200mm	New	D3M765	Back-up column Received 9/24/09.	2009-09-24 09:00:47
1020	Boron_01	n/a	n/a	n/a	Handpacked by Qibin Zhang	Pierce material	Unk	Boronate affinity	Unk	Unk	Unk	Retired	d3m765	Qibin's boron column 1	2009-10-28 07:52:39
1021	SCX-200-08	Poly LC  PolysulfoethylA	P202SE0503	I0292B	Poly LC	SCX	5 um	300-A	N/A	2.1mm	200mm	Retired	D3M765	Use for human plasma only! Replacement column for SCX-200-05 that was sent to Broad. Received 10/30/09.	2009-11-02 10:05:29
1022	Human_IgY14_LC10_01a	Seppro IgY14 LC10	28-288-12014-LC10	LN070411	Genway	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Weijun's old IgY14 LC10 column. May 2007. 125 runs on it previously.	2009-11-13 09:14:28
1025	XBridge_001	Waters XBridge	186003117	0121381491	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3L365	Feng Yang's column - see Marina/Feng before use	2009-11-13 11:57:15
1026	IgY12_LC2_01	Beckman Coulter-ProteomeLab	A24346	070131017	Beckman Coulter-ProteomeLab	Ig antibodies	n/a	Ig antibodies	n/a	n/a	n/a	Retired	d3m765	For EIF use. Exp date: 1/31/09.	2009-11-20 08:16:33
1027	Human_Supermix_04	Seppro Supermix LC5	S5324-1EA	129K6063	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tom Metz's new Supermix column. 1/27/10	2010-01-27 13:16:36
1028	Human_IgY14_LC10_04	Seppro IgY14 LC10	S5074-1EA	119K6039	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tom Metz's new IgY14 LC10 column. 1/27/10	2010-01-27 13:25:48
1029	Human_IgY14_LC10_02	Seppro IgY14 LC10	28-288-12014-LC10	LN080321	Genway	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tom's old IgY14 LC10 column. 12/22/08. 192 runs prior to DMS logging system.	2010-04-14 10:32:04
1030	Human_IgY14_LC10_05	Seppro IgY14 LC10	S5074-1EA	128K0506	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tom Metz's IgY14 LC10 column. 5/20/09. 67 runs on column prior to DMS logging system.	2010-04-14 10:37:42
1031	XBridge_002	Waters XBridge	186003117	0129393441	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3P704	Mary Lipton's column - See Erika/Mary before use.	2010-05-20 11:37:21
1032	Human_IgY14_LC10_07	Seppro IgY14 LC10	S5074-1EA	050M6007	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tom Metz's IgY14 LC10 column. 5/25/10. SL10204	2010-05-25 15:26:30
1033	Human_IgY14_LC10_08	Seppro IgY14 LC10	S5074-1EA	050M6007	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tom Metz's IgY14 LC10 column. 5/25/10. SL10204	2010-05-25 15:32:18
1034	Human_IgY14_LC10_06	Seppro IgY14 LC10	S5074-1EA	050M6007	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tom Metz's IgY14 LC10 column. 5/25/10. SL10204	2010-05-25 15:32:58
1035	Human_Supermix_05	Seppro Supermix LC5	S5324-1EA	020M6235	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao Liu's Supermix column for EIF. 5/25/10. SL10105	2010-05-26 08:13:08
1036	Human_IgY14_LC10_09	Seppro IgY14 LC10	S5074-1EA	050M6007	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao Liu's IgY14 LC10 column for EIF. 5/25/10. SL10204	2010-05-26 08:14:38
1037	XBridge_003	Waters XBridge	186003117	0129394413643	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3L365	NCRR Mammalian General Use Column	2010-06-09 15:22:10
1038	XBridge_004	Waters XBridge	186003117	01293934413638	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3L365	NCRR HUMAN Sample Column	2010-06-09 15:22:30
1039	SCX-200-09	Poly LC  PolysulfoethylA	P202SE0503	I0292D	Poly LC	SCX	5 um	300-A	N/A	2.1mm	200mm	Active	D3L365	In 2240	2010-06-09 15:45:29
1040	SCX-200-10	Poly LC  PolysulfoethylA	P202SE0503	A1391I	Poly LC	SCX	5 um	300-A	N/A	2.1mm	200mm	New	D3L365	New Replacement column - not conditioned!	2010-06-09 15:45:36
1041	SCX-9mm-200-01	Poly LC  PolysulfoethylA	209SE0503	F18920	Poly LC	SCX	5 um	300-A	N/A	9.4mm	200mm	New	D3P704	Large SCX column for Prokaryotic Phosphopeptide enrichment fractionations	2010-07-08 14:14:39
1042	XBridge_005	Waters XBridge	186003117	013330125138 32	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3L365	RETIRED - NO LONGER IN SERVICE	2010-07-08 15:28:14
1045	ZorbaxC18_50	Agilent Zorbax	765750-902	USUG001189	Agilent	Silica	3.5 um	C18	2.1 mm?	15 mm?	50 mm	Active	EMSL1521	For use with high pH reverse phase separations--small column.	2010-07-15 07:55:19
1046	Boron_01_062410	n/a	n/a	n/a	Handpacked by Qibin Zhang	Pierce material	Unk	Boronate affinity	Unk	Unk	Unk	Retired	d3m765	Qibin's boron column 1, packed on 6/24/10	2010-07-21 12:48:30
1047	Boron_02_062410	n/a	n/a	n/a	Handpacked by Qibin Zhang	Pierce material	Unk	Boronate affinity	Unk	Unk	Unk	Retired	d3m765	Qibin's boron column 2, packed on 6/24/10	2010-07-21 12:48:44
1048	Human_IgY14_LC5_01	Seppro IgY14 LC5	S4949-1EA	129K6067	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Qibin's IgY14 LC5 column. 8/4/10. SL09522	2010-08-04 09:31:41
1049	Human_IgY14_SuMix_01	IgY14 Supermix Combo 1 to 2	Custom	129K6041	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	IgY14 Supermix combo column 1 to 2 ratio. 5/25/10. 040M6057	2010-08-05 07:39:48
1050	Human_IgY14_SuMix_02	IgY14 Supermix Combo 2 to 1	Custom	129K6041	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	IgY14 Supermix combo column 2 to 1 ratio. 6/23/10. 040M6057	2010-08-16 07:50:51
1051	Human_IgY14_LC10_10	Seppro IgY14 LC10	S5074-1EA	050M6007	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Erin Baker's IgY14 LC10 column. 5/25/10. SL10204	2010-09-03 14:01:56
1052	Human_IgY14_LC10_11	Seppro IgY14 LC10	S5074-1EA	060M6130	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Weijun Qian's IgY14 LC10 column. 9/6/10. SL10254	2010-09-03 14:04:25
1053	Human_Supermix_06	Seppro Supermix LC5	S5324-1EA	020M6235	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Weijun Qian's Supermix column. 9/3/10. SL10105	2010-09-03 14:16:19
1054	Mouse_M7_03	Seppro Mouse LC10	S5699-1EA	060M6129	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3L365	U54 (J.Jacobs) new M7 column. 9/08/10	2010-09-08 12:13:59
1055	Human_IgY14_LC20_01	Seppro IgY14 LC20	SEP000-1KT	090M6039	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's EIF column. SL09332. 10/16/10.	2010-10-18 08:53:50
1056	Human_SuMix_LC10_01	Seppro Supermix LC10	SEP000-1KT	090M6037	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's EIF column. SL09332. 10/16/10.	2010-10-18 08:55:55
1058	JupiterC4	Phenomenex	00G-4167-B0	551503-6	Jupiter	C4	5 um	300A	2.0 mm	?	250 mm	New	d3h534	Used for separating PROTEINS only	2010-10-21 16:51:51
1059	Human_IgY14_LC20_02	Seppro IgY14 LC20	SEP000-1KT	090M6039	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's EIF column. SL09332. 10/16/10.	2011-01-03 08:51:15
1060	Human_SuMix_LC10_02	Seppro Supermix LC10	SEP000-1KT	090M6037	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Active	D3M765	Tao's EIF column. SL09332. 10/16/10.	2011-01-03 08:51:35
1061	Human_IgY12_LC10_01	Seppro IgY12 LC10	SEP000-1KT	011M6032	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's column. 1/18/11. SL09332.	2011-01-18 13:58:34
1062	IgY12_LC2_02	Beckman Coulter-ProteomeLab	A24346	070131011	Beckman Coulter-ProteomeLab	Ig antibodies	n/a	Ig antibodies	n/a	n/a	n/a	Retired	D3L365	For U54 use. Exp date: 1/31/09.	2011-01-28 12:53:15
1063	IgY12_LC2_03	Beckman Coulter-ProteomeLab	A24346	070131022	Beckman Coulter-ProteomeLab	Ig antibodies	n/a	Ig antibodies	n/a	n/a	n/a	Retired	D3L365	For U54 use. Exp date: 1/31/09.	2011-01-28 17:04:10
1064	Human_IgY14_LC20_03	Seppro IgY14 LC20	SEP000-1KT	090M6039	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's EIF column. SL09332. 10/16/10.	2011-02-22 10:49:35
1065	Human_SuMix_LC10_03	Seppro Supermix LC10	SEP000-1KT	090M6037	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's EIF column. SL09332. 10/16/10.	2011-02-22 10:49:50
1066	Human_IgY14_LC5_02	Seppro IgY14 LC5	S4949-1EA	090M6078	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	EDRN's IgY14 LC5 column. 2/22/11. SL10375	2011-02-22 16:04:01
1067	Human_IgY14_LC10_12	Seppro IgY14 LC10	S5074-1EA	090M6183	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Active	D3M765	EDRN's IgY14 LC10 column. 2/22/11. SL10433	2011-02-22 16:06:05
1068	Human_Supermix_07	Seppro Supermix LC5	S5324-1EA	020M6115	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	3/8/11. SL11021	2011-03-09 08:11:58
1069	Human_IgY14_LC10_13	Seppro IgY14 LC10	S5074-1EA	090M6183	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	3/8/11. SL10433	2011-03-09 08:16:03
1070	Human_IgY14_LC20_04	Seppro IgY14 LC20	SEP000-1KT	090M6039	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	Tao's EIF column. SL09332. 10/16/10.	2011-03-18 12:18:33
1074	GraphitizedCarbon60CM_1_SRK	Packed by Scott Kronewitter to ~6,500 psi	Inhouse packing 1 column at a time	1	PolyMicro	PolyMicro	3um	HyperCarb	150um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 150id 60cm #1 04/12/11.  Cut up  during IMS run to get high flow rates	2011-04-22 10:47:10
1075	Human_IgY14_LC10_14	Seppro IgY14 LC10	S5074-1EA	090M6183	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	5/2/11. SL10433. EDRN Use only.	2011-05-03 14:46:52
1076	Human_Supermix_08	Seppro Supermix LC5	S5324-1EA	120M6115	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	5/2/11. SL11021. EDRN Use Only.	2011-05-03 15:12:42
1077	SEC200_03	Superdex 200 10/300 GL	17-5175-01	10050642	GE Healthcare	SEC particles	unknown	SEC	n/a	n/a	n/a	Active	D3Y467	Tao's SEC. Expires 11/2015. Received on 2/7/2011. First use on 5/19/2011.	2011-05-19 16:30:41
1078	GraphitizedCarbon60CM_2_SRK	Packed by Scott Kronewitter to ~6,500 psi	Inhouse packing 1 column at a time	2	PolyMicro	PolyMicro	3um	HyperCarb	150um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 150id 60cm #2 04/12/11, Used 7-2011 Orb 3.  Scould be good	2011-07-25 13:30:28
1079	GraphitizedCarbon60CM_3_SRK	Packed by Scott Kronewitter to ~6,500 psi	Inhouse packing 1 column at a time	3	PolyMicro	PolyMicro	3um	HyperCarb	150um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 150id 60cm #3 04/12/11.  Unknown condition.  It could be new.  or ...., May have been killed by sialic acid reaction but I don't know.  This one should be tested and or measured to see if it has been cut down to size	2011-07-25 13:32:04
1080	GraphitizedCarbon60CM_4_SRK	Packed by Scott Kronewitter to ~6,500 psi	Inhouse packing 1 column at a time	4	PolyMicro	PolyMicro	3um	HyperCarb	150um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 150id 60cm #4 04/12/11.  New	2011-07-25 13:32:10
1081	GraphitizedCarbon60CM_5_SRK	Packed by Scott Kronewitter to ~6,500 psi	Inhouse packing 1 column at a time	5	PolyMicro	PolyMicro	3um	HyperCarb	150um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 150id 60cm #5 04/12/11.  Unknown condition.  May have been killed by sialic acid reaction but I don't know.  Killed with rat gut sample 9-11-11.  it was fine before that	2011-07-25 13:32:16
1082	GraphitizedCarbon60CM_75_1_SRK	Packed by Scott Kronewitter to ~6,500 psi	Inhouse packing 1 column at a time	1	PolyMicro	PolyMicro	3um	HyperCarb	75um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 75id 60cm #1 05/02/11.  Killed on High throughput digestion set	2011-07-25 13:35:52
1083	GraphitizedCarbon60CM_75_2_SRK	Packed by Scott Kronewitter to ~6,500 psi	Inhouse packing 1 column at a time	2	PolyMicro	PolyMicro	3um	HyperCarb	75um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 75id #2 06/01/11, Should be good.  Used 7-25-11, clipped end but should be ok.  QC Load!!!!! 9-8-11  Possible damage.	2011-07-25 13:36:03
1084	GraphitizedCarbon60CM_75_3_SRK	Packed by Scott Kronewitter to ~8,500 psi	Inhouse packing 1 column at a time	3	PolyMicro	PolyMicro	3um	HyperCarb	75um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 75id #3 09/06/11, Should be good.  The packing went extremely fast and the depressurization was fast as well.  It may not be as dense as the others.  It needs to be checked to see if it is ok.  Bad Frit.	2011-09-06 09:10:52
1085	GraphitizedCarbon60CM_75_4_SRK	Packed by Scott Kronewitter to ~8,500 psi	Inhouse packing 1 column at a time	4	PolyMicro	PolyMicro	3um	HyperCarb	75um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 75id #4 09/06/11, Great.  Possible QC Load!!! 9-8-11.	2011-09-06 09:11:15
1086	GraphitizedCarbon60CM_75_5_SRK	Packed by Scott Kronewitter to ~8,500 psi	Inhouse packing 1 column at a time	5	PolyMicro	PolyMicro	3um	HyperCarb	75um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 75id #5 09/07/11, Great	2011-09-08 11:44:22
1087	GraphitizedCarbon60CM_75_6_SRK	Packed by Scott Kronewitter to ~8,500 psi	Inhouse packing 1 column at a time	6	PolyMicro	PolyMicro	3um	HyperCarb	75um	360um	60cm	Retired	kron626	SRK, SK Hypercarb 3um 75id #6 09/07/11, Great	2011-09-08 11:44:40
1088	Human_IgY14_LC10_15	Seppro IgY14 LC10	S5074-1EA	090M6183	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	9/21/11. SL10433. See Josh Adkins if you want to use this.	2011-09-21 11:18:07
1089	Human_Supermix_09	Seppro Supermix LC5	S5324-1EA	120M6115	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	9/21/11. SL11021. See Josh Adkins to use.	2011-09-21 11:26:54
1090	Human_IgY14_LC10_16	Seppro IgY14 LC10	S5074-1EA-KC	031M6135	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	10/4/11. SL11134. EDRN Column. See Tao if you want to use this.	2011-10-07 08:51:33
1091	XBridge_006	Waters XBridge	186003117	014932189138	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3L365	CPTAC column - see Marina/Feng/Tao before use	2012-05-31 11:08:23
1094	ZIC-HILIC_150x4-6_01	The Nest Group, Inc.	ZIC-HILIC	Q150449S32-155	The Nest Group, Inc.	ZIC-HILIC C18	200 A	C18	3.5 um	4.6 mm	150 mm	New	d3p704	SW intramural only.  See Sisi before using	2012-06-29 12:46:54
1095	Human_IgY14_LC10_17	Seppro IgY14 LC10	S5074-1EA-KC	031M6135	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	8/7/12. SL11134. See Josh Adkins or Jon Jacobs if you want to use this.	2012-08-07 14:24:07
1096	Human_Supermix_10	Seppro Supermix LC5	S5324-1EA	031M6136	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	8/7/12. SL11134. See Josh Adkins to use.	2012-08-07 14:26:03
1097	SEC_Yarra_3u_01	Yarra 3u SEC-2000	00H-4512-KO	633588-5	Phenomenex	SEC	3um	SEC	unk	7.80mm	300mm	Active	d3m765	B/N 5622-15. Ask Qibin before using.	2012-09-05 08:11:25
1098	Human_IgY14_LC5_03	Seppro IgY14 LC5	S4949-1EA	1001235007	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	EDRN's IgY14 LC5 column. 5/1/13. Lot SLBB1542V	2013-05-01 14:35:18
1099	Human_IgY14_LC5_04	Seppro IgY14 LC5	S4949-1EA	1001235007	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Retired	D3M765	EDRN's IgY14 LC5 column. 5/1/13. Lot SLBB1542V	2013-05-01 14:35:25
1100	XBridge_007	Waters XBridge	186003117	0154331471	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3J704	General Use	2013-09-17 15:53:25
1102	Human_IgY14_LC2_01	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:00:43
1103	Human_IgY14_LC2_02	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:03:03
1104	Human_IgY14_LC2_03	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:03:07
1105	Human_IgY14_LC2_04	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:03:12
1106	Human_IgY14_LC2_05	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:03:17
1107	Human_IgY14_LC2_06	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:03:22
1108	Human_IgY14_LC2_07	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:03:26
1109	Human_IgY14_LC2_08	Sigma	Seppro	20269324	Seppro	IgY14	N/A	Ig antibodies	N/A	N/A	N/A	Active	cham566	TB project only	2013-10-21 09:03:30
1110	Human_IgY14_LC2_09	Sigma	Seppro	SLBF3997	Seppro	IgY14	N/A	N/A	N/A	N/A	N/A	Active	D3M765	SL 13032. See Tom Metz or Jon Jacobs for use.	2014-01-17 07:19:52
1112	Human_MARS_14_100mm_01	Multi Affinity Removal Column	5189-6558	100576543H	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	See Qibin for use. Received 4/3/14	2014-04-04 06:10:48
1113	Human_MARS_14_100mm_02	Multi Affinity Removal Column	5189-6558	100576543M	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	See Qibin for use. Received 4/3/14	2014-04-04 06:12:48
1114	Human_MARS_14_100mm_03	Multi Affinity Removal Column	5189-6558	100576543K	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	See Qibin for use. Received 4/3/14	2014-04-04 06:14:30
1115	Human_MARS_14_100mm_04	Multi Affinity Removal Column	5189-6558	100576543L	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	See Qibin for use. Received 4/3/14	2014-04-04 06:16:32
1116	Human_MARS_14_100mm_05	Multi Affinity Removal Column	5189-6558	100576543G	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	See Qibin for use. Received 4/3/14	2014-04-04 06:17:57
1117	XBridge_008	Waters XBridge	186003117	01603413913856	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3M765	Mammalian Sample Column	2014-07-17 10:39:12
1118	XBridge_009	Waters XBridge	186003117	01623424613853	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3M765	for TEDDY	2014-10-24 15:26:06
1119	XBridge_010	Waters XBridge	186003117	01683502813827	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3M765	replacement for XBridge 001 (method development) - ask Marina	2014-10-31 09:16:18
1120	Human_MARS_14_100mm_06	Multi Affinity Removal Column	5188-6558	100652245A	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	TEDDY Use Only. Received 10/31/14	2014-11-05 10:44:17
1121	Human_MARS_14_100mm_07	Multi Affinity Removal Column	5188-6558	100652245B	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	TEDDY Use Only. Received 10/31/14	2014-11-20 10:48:24
1122	Human_MARS_14_100mm_08	Multi Affinity Removal Column	5188-6558	100652245C	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	TEDDY Use Only. Received 10/31/14	2014-11-20 10:48:53
1123	Human_MARS_14_100mm_09	Multi Affinity Removal Column	5188-6558	100652245D	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	TEDDY Use Only. Received 10/31/14	2014-11-20 10:49:22
1124	Human_MARS_14_100mm_10	Multi Affinity Removal Column	5188-6558	100652245E	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	TEDDY Use Only. Received 10/31/14	2014-11-20 10:49:53
1125	Human_MARS_14_100mm_11	Multi Affinity Removal Column	5188-6558	100589951E	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	d3m765	TEDDY Use Only. Received 10/31/14	2014-11-20 10:50:31
1126	XBridge_011	Waters XBridge	186003117	01603413913834	Waters	silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3H534	New column for BSF 1206	2016-06-09 10:44:17
1127	XBridge_012	Waters XBridge	186003117	01783614023826	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3H534	CPTAC prospective column	2016-08-10 11:46:02
1128	XBridge_013	Waters XBridge	186003117	01783614023830	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3M765	Athena's column. Please ask before using.	2016-09-02 06:13:07
1129	XBridge_014	Waters XBridge	186003117	1	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Retired	D3K875	Carrie's column. Please ask before using.	2016-09-09 17:06:18
1130	XBridge_015	Waters XBridge	186003117	018113631523891	Waters	Silica	5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	CPTAC Column- See Marina/Tao before use	2016-12-20 10:50:51
1131	Human_Mars_14_100mm_12	Multi Affinity Removal Column	5188-6558	100780583K	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	D3L365	Erin Baker/Pregnancy Study. Exp 06/30/2018	2016-12-20 10:58:15
1134	Rep-CFE-001	\N	\N	\N	ReproSil-Pur 120 C18-AQ	Column with Frit	1.9	Batch 5910	75um	360	33CM	New	D3L282	\N	2016-12-22 08:40:23
1135	Rep-CFE-002	\N	\N	\N	ReproSil-Pur 120 C18-AQ	Column with Frit	1.9	Batch 5910	75um	360	33CM	New	D3L282	\N	2016-12-22 08:41:08
1136	Rep-CFE-003	\N	\N	\N	ReproSil-Pur 120 C18-AQ	Column with Frit	1.9	Batch 5910	75um	360	33CM	New	D3L282	\N	2016-12-22 08:41:43
1137	Rep-CFE-004	\N	\N	\N	ReproSil-Pur 120 C18-AQ	Column with Frit	1.9	Batch 5910	75um	360	33CM	New	D3L282	\N	2016-12-22 08:42:09
1146	Human_Mars_14_100mm_13	Multi Affinity Removal Column	5188-6558	100780583G	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	D3M765	Jon Jacobs AH_Betaine project. Exp 06/30/2018	2017-02-08 09:12:14
1147	XBridge_016	Waters XBridge	186003117	01793619533818	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3H534	Heather's column. Please ask before using.	2017-02-22 11:45:00
1148	Human_Mars_14_100mm_14	Multi Affinity Removal Column	5188-6558	100818123A	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3M765	Metz Zika Project Use Only! Exp 03/30/2019	2017-04-25 09:46:47
1149	Human_Mars_14_100mm_15	Multi Affinity Removal Column	5188-6558	100818123J	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3M765	Metz Zika Project Use Only! Exp 03/30/2019	2017-04-25 09:47:41
1150	XBridge_017	Waters XBridge	186003943	01813620214603	Waters	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Retired	D3L365	CPTAC Column- See Marina/Tao before use	2017-04-28 10:52:15
1151	ZORBAX_001	ZORBAX	custom	USDHP01054	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	CPTAC method development / other use - See Marina/Tao before use	2017-04-28 10:57:14
1152	XBridge_018	Waters XBridge	186003117	01823635612492	Waters	Silica	5 um	C18	4.6 mm	10 mm	250mm	Active	D3J704	Hixson Plant Column- See Kim before use (Passivated on 06/05/2017 by Erika Zink)	2017-06-05 11:02:51
1153	XBridge_019	Waters XBridge	186003117	01793619533819	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3K875	Carrie column. Please ask before using.	2017-06-08 09:13:43
1154	Human_Mars_14_100mm_16	Multi Affinity Removal Column	5188-6558	100841828B	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	D3M765	AH Project. See Jon Jacobs before using. Exp 04/30/2019	2017-07-28 06:06:57
1155	Human_IgY14_LC5_05	Seppro IgY14 LC5	S4949-1EA	1002214038	Sigma	IgY	N/A	Ig antibodies	N/A	N/A	N/A	Active	D3M765	See Tao or Weijun before use! 6/30/17. Lot SLBP7519V	2017-08-24 10:52:41
1156	ZORBAX_002	ZORBAX	custom	USDHP01071	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Retired	D3L365	CPTAC3 UCEC Use Only	2017-09-13 12:01:41
1157	ZORBAX_003	ZORBAX	custom	USDHP01072	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	CPTAC3 GBM Use Only	2017-09-13 12:02:09
1158	ZORBAX_004	ZORBAX	custom	USDHP01078	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Retired	D3L365	Exclusively for PTRC. POC-P. Piehowski; M. Gritsenko	2017-11-20 10:35:26
1159	ZORBAX_005	ZORBAX	custom	USDHP01081	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	Exclusively for MoTrPAC - method development and tests. POC-P.Piehowski; M.Gritsenko	2017-12-22 15:27:27
1160	Human_Mars_14_100mm_17	Multi Affinity Removal Column	5188-6558	100893492A	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	D3L365	TB Project. See Jon Jacobs before using. Exp 12/30/2019	2018-02-16 09:32:06
1161	Human_Mars_14_100mm_18	Multi Affinity Removal Column	5188-6558	100893492H	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Retired	D3L365	TB Project. See Jon Jacobs before using. Exp 12/30/2019	2018-03-23 14:36:46
1162	Human_Mars_14_50mm_01	Multi Affinity Removal Column	5188-6557	100886770B	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot project. See Tao or Tujin before using., Exp 12/30/19, Resin 0006361506	2018-03-27 07:03:34
1163	Human_Mars_14_50mm_02	Multi Affinity Removal Column	5188-6557	100886770C	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot project. See Tao or Tujin before using., Exp 12/30/19, Resin 0006361506	2018-03-27 07:03:47
1164	Human_Mars_14_50mm_03	Multi Affinity Removal Column	5188-6557	100886770D	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot project. See Tao or Tujin before using., Exp 12/30/19, Resin 0006361506	2018-03-27 07:04:00
1165	Human_Mars_14_50mm_04	Multi Affinity Removal Column	5188-6557	100886770G	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot project. See Tao or Tujin before using., Exp 12/30/19, Resin 0006361506	2018-03-27 07:04:13
1166	Human_Mars_14_50mm_05	Multi Affinity Removal Column	5188-6557	100886770M	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot project. See Tao or Tujin before using., Exp 12/30/19, Resin 0006361506	2018-03-27 07:04:24
1167	Human_Mars_14_50mm_06	Multi Affinity Removal Column	5188-6557	100886770A	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot project. See Tao or Tujin before using., Exp 12/30/19, Resin 0006361506	2018-04-17 07:52:41
1168	ZORBAX_006	ZORBAX	custom	USDHP01097	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Retired	D3L365	Exclusively for MoTrPAC - animal study. POC-P.Piehowski; M.Gritsenko	2019-02-21 15:57:16
1169	Human_Mars_14_100mm_19	Multi Affinity Removal Column	5188-6558	100992440C	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3M765	Zika project. See Tom Metz before using. Resin 0006401415. Exp 11/30/20	2019-05-01 11:56:05
1170	Human_Mars_14_100mm_20	Multi Affinity Removal Column	5188-6558	100992440D	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3M765	Zika project. See Tom Metz before using. Resin 0006401415. Exp 11/30/20	2019-05-01 11:56:19
1171	ZORBAX_007	ZORBAX	custom	USDHP01132	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	Vlad's Exclusive. POC-Marina Gritsenko	2019-06-21 16:21:02
1172	Human_Mars_14_50mm_07	Multi Affinity Removal Column	5188-6557	101024331Q	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	See Weijun before using., Exp 6/30/21, Resin 0006428887	2019-10-23 08:03:37
1173	Human_Mars_14_100mm_21	Multi Affinity Removal Column	5188-6558	101024510B	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3L365	BRAVE use only (POC - Marina Gritsenko). Exp 06/30/2021	2020-01-24 14:45:22
1174	Human_Mars_14_100mm_22	Multi Affinity Removal Column	5188-6558	101098188E	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3M765	See Weijun Qian before using. Resin 0006428887. Exp 01/30/22	2020-07-13 15:11:26
1175	Human_Mars_14_100mm_23	Multi Affinity Removal Column	5188-6558	101196117P	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3L365	AH (J. Jacobs). Exp 10/30/2022	2021-01-08 10:54:59
1176	ZORBAX_008	ZORBAX	custom	USDHP01096	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	Exclusively for MoTrPAC - human study. POC-P.Piehowski; M.Gritsenko	2021-02-17 13:49:47
1177	Human_Mars_14_100mm_24	Multi Affinity Removal Column	5188-6558	101230463E	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3L365	NAMRU use only (POC - Marina Gritsenko). Exp 01/30/2023	2021-03-15 15:43:31
1178	ZORBAX_009	ZORBAX	custom	USDHP01044	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Retired	D3L365	For Clinical Projects; POC-Marina Gritsenko	2021-04-08 15:55:48
1179	Human_Mars_14_50mm_08	Multi Affinity Removal Column	5188-6557	101254264G	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	See Tao Liu before using., Exp 4/30/23, Resin 0006551525	2021-06-09 07:46:41
1180	Human_Mars_14_100mm_25	Multi Affinity Removal Column	5188-6558	101125426K	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3L365	 EMSL_COVID_Trivedi (P.Piehowski) Exp 02/28/2023	2021-08-21 13:25:09
1181	Human_Mars_14_50mm_09	Multi Affinity Removal Column	5188-6557	101312277B	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:08:49
1182	Human_Mars_14_50mm_10	Multi Affinity Removal Column	5188-6557	101312277C	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:09:37
1183	Human_Mars_14_50mm_11	Multi Affinity Removal Column	5188-6557	101312277D	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:10:24
1184	Human_Mars_14_50mm_12	Multi Affinity Removal Column	5188-6557	101312277E	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:11:11
1185	Human_Mars_14_50mm_13	Multi Affinity Removal Column	5188-6557	101312277F	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:11:56
1186	Human_Mars_14_50mm_14	Multi Affinity Removal Column	5188-6557	101312277G	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:12:44
1187	Human_Mars_14_50mm_15	Multi Affinity Removal Column	5188-6557	101312277H	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:13:39
1188	Human_Mars_14_50mm_16	Multi Affinity Removal Column	5188-6557	101312277J	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:14:19
1189	Human_Mars_14_50mm_17	Multi Affinity Removal Column	5188-6557	101312277K	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:15:21
1190	Human_Mars_14_50mm_18	Multi Affinity Removal Column	5188-6557	101312277L	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:16:02
1191	Human_Mars_14_50mm_19	Multi Affinity Removal Column	5188-6557	101312277M	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:17:01
1192	Human_Mars_14_50mm_20	Multi Affinity Removal Column	5188-6557	101312277N	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:18:02
1193	Human_Mars_14_50mm_21	Multi Affinity Removal Column	5188-6557	101312277R	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:18:42
1194	Human_Mars_14_50mm_22	Multi Affinity Removal Column	5188-6557	101312277S	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Moonshot Project. See Tao Liu before using., Exp 8/30/23, Resin 0006583844	2021-08-27 13:19:22
1195	Human_Mars_14_100mm_26	Multi Affinity Removal Column	5188-6558	101324543D	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3L365	TB Smart use only (Jon Jacobs). Exp. 09/30/2023	2022-03-30 13:59:15
1196	Human_Mars_14_100mm_27	Multi Affinity Removal Column	5188-6558	101324543P	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3L365	TB Smart use only (Jon Jacobs). Exp. 09/30/2023	2022-03-30 14:38:34
1197	Human_Mars_14_100mm_28	Multi Affinity Removal Column	5188-6558	101324544P	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	100 mm	Active	D3L365	TB Vaccine Correlates Project (J.Kyle). Exp 11/30/2023	2022-05-06 10:15:52
1198	ZORBAX_010	ZORBAX	custom	USDHP01226	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Retired	D3L365	Exclusevely for CPTAC 4; POC-Marina Gritsenko	2023-02-27 17:53:17
1199	ZORBAX_011	ZORBAX	custom	USDHP01227	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Retired	D3L365	Exclusively for MoTrPAC - animal study 2. POC-P.Piehowski; M.Gritsenko	2023-02-27 17:54:58
1200												New	d3g716		2023-04-05 16:49:05
1201	Human_Mars_14_50mm_23	Multi Affinity Removal Column	5188-6557	101510663J	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Macaque Project. See Jon Jacobs before using.	2023-06-08 06:50:06
1202	Human_Mars_14_50mm_24	Multi Affinity Removal Column	5188-6557	101510663C	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Retired	D3M765	Macaque Project. See Jon Jacobs before using. 7/23: Column is defective. It is being returned to Agilent.	2023-06-08 06:50:19
1203	Human_Mars_14_50mm_25	Multi Affinity Removal Column	5188-6557	101510663U	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Macaque Project. See Jon Jacobs before using.	2023-07-08 18:05:32
1204	23-07-01				Separation Methods Technologies - C2	Column with Frit	3um	MEB2-3-300, C2	75um	360um	68cm	New	ROSE554	Packed at 8000psi and let depressurize over night	2023-07-25 12:27:11
1205	23-07-02				Separation Methods Technologies - C2	Column with Frit	3um	MEB2-3-300, C2	75um	360um	70cm	New	ROSE554	Packed at 8000psi and let depressurize over night	2023-07-25 12:27:54
1206	23-07-03				Separation Methods Technologies - C2	Column with Frit	3um	MEB2-3-300, C2	75um	360um	71cm	New	ROSE554	Packed at 8000psi and let depressurize over night	2023-07-25 12:28:11
1207	23-07-04				Separation Methods Technologies - C2	Column with Frit	3um	MEB2-3-300, C2	75um	360um	66cm	New	ROSE554	Packed at 8000psi and let depressurize over night	2023-07-25 12:28:20
1208	Human_Mars_14_50mm_26	Multi Affinity Removal Column	5188-6557	101514206G	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Macaque Project. See Jon Jacobs before using.	2023-10-17 05:11:00
1209	Human_Mars_14_50mm_27	Multi Affinity Removal Column	5188-6557	101514206M	Agilent	Antibodies	n/a	Antibodies	n/a	4.6	50 mm	Active	D3M765	Macaque Project. See Jon Jacobs before using.	2023-10-17 05:11:13
1210	ZORBAX_012	ZORBAX	custom	USDHP01240	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	KidsFirst_POC- M.Gritsenko	2024-01-03 12:26:30
1211	XBridge_020	Waters XBridge	186003943	02493324013808	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3L365		2024-01-03 13:57:03
1212	XBridge_021	Waters XBridge	186003581	02533402413311	Waters	Silica	5 um, 130A	BEH C18	4.6 mm	10 mm	250 mm	Active	D3J704	Lot. No.  0253340241, Acquired 04/2024	2024-04-30 12:57:18
1213	ZORBAX_013	ZORBAX	custom	USDHP01254	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	Exclusively for MoTrPAC. POC- M. Gritsenko	2024-08-07 11:57:02.601112
1214	ZORBAX_014	ZORBAX	custom	USDHP01255	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	Exclusively for CPTAC4. POC- M. Gritsenko	2024-08-07 11:57:44.862537
1215	XBridge_022	Waters XBridge	186003117	02493418613896	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3H534	Heather's column. Please ask before using.	2024-08-20 14:25:20.413553
1216	XBridge_023	Waters XBridge	186003117	02493405212488	Waters	Silica	5 um	C18	4.6 mm	10 mm	250 mm	Active	D3M765	Athena's new column. Please ask before using.	2024-09-03 12:45:18.569008
1217	ZORBAX_015	ZORBAX	custom	USDHP01257	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	For Clinical Projects; POC-Marina Gritsenko	2025-01-29 16:30:27.389084
1218	ZORBAX_016	ZORBAX	custom	USDHP01256	Agilent	Silica	3.5 um	C18	4.6 mm	10 mm	250mm	Active	D3L365	Alz Buchman project	2025-02-17 16:30:30.556229
\.


--
-- Name: t_prep_lc_column_prep_column_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_prep_lc_column_prep_column_id_seq', 1218, true);


--
-- PostgreSQL database dump complete
--

