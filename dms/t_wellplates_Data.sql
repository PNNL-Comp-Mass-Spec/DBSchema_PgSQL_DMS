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
-- Data for Name: t_wellplates; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_wellplates (wellplate_id, wellplate, description, created) FROM stdin;
1000	na	(no wellplate)	2009-07-24 20:10:02
1001	ABS_VP2P106	Created by experiment fraction entry (ABS_VP2P106)	2009-07-30 17:49:07
1002	COPD_ADA_Lung_PosPool	Created by experiment fraction entry (COPD_ADA_Lung_PosPool)	2009-08-13 14:50:52
1003	WP-1003	HPlas_IgY12_FT2_08 SCX fractions	2009-08-20 14:27:05
1004	SBEP_STM_PTM_001	Created by experiment fraction entry (SBEP_STM_PTM_001_06232009)	2009-08-25 13:19:00
1005	WP-1005	Baynes2SC Mouse Adipocyte Proteins	2009-08-26 14:02:42
1006	SBEP_STM_PTM_003	Created by experiment fraction entry (SBEP_STM_PTM_003_06232009)	2009-08-27 10:24:44
1007	SBEP_STM_PTM_006	Created by experiment fraction entry (SBEP_STM_PTM_006_06232009)	2009-08-27 10:25:22
1008	SBEP_STM_PTM_008	Created by experiment fraction entry (SBEP_STM_PTM_008_06232009)	2009-08-27 10:25:50
1009	SH_SBI_04a	Created by experiment fraction entry (SH_SBI_04a)	2009-08-27 12:41:16
1010	SBEP_YPCO_007	Created by experiment fraction entry (SBEP_YPCO_007_07102009)	2009-08-27 12:46:11
1011	SBEP_YPCO_008	Created by experiment fraction entry (SBEP_YPCO_008_07102009)	2009-08-27 12:46:29
1012	WP-1012	JGI fungus_06, Carries Re_Averia	2009-08-31 08:30:49
1013	Micromonas_pool	Created by experiment fraction entry (Micromonas_pool)	2009-10-09 14:53:55
1014	Euplotes_1_SCX	Created by experiment fraction entry (Euplotes_1_SCX)	2009-11-09 15:14:17
1015	SysVirol_ICL004_AI_SCX	SysVirol_ICL004_AI_Pool 1_0,3,7 hrs (1 thru 24), SysVirol_ICL004_AI__Pool 2_12,18,24 hrs (1 thru 24), SysVirol_ICL004_AI_Pool 3_Mock 0-24 hrs (1 thru 24),	2009-11-10 14:00:10
1016	WP-1016	Multi-enzyme digestion of Ecoli - fractions	2009-11-30 13:23:14
1017	WP-1017	150ug of NCI_NormalFFPool, NCI_NormalBFPool, NCI_CancerFFPool, NCI_CancerBFPool	2010-01-13 08:16:27
1018	WP-1018	Cornell_RK4353-WT_pool - Fractions from 4 wild type cell cultures that were pooled for database creation.	2010-01-14 13:10:25
1019	WP-1019	Yellow_C12 & C13	2010-01-18 16:54:20
1021	WP-1020	Yellow_C13	2010-01-18 16:54:36
1022	SBEP_STM_01	Created by experiment fraction entry (1911)	2010-01-19 12:02:45
1023	SBEP_STM_02	Created by experiment fraction entry (1914)	2010-01-19 12:10:18
1024	SBEP_STM_03	Created by experiment fraction entry (1916)	2010-01-19 12:13:18
1025	SBEP_STM_04	Created by experiment fraction entry (1920)	2010-01-19 12:16:15
1026	SBEP_STM_05	Created by experiment fraction entry (1922)	2010-01-19 12:17:53
1027	SBEP_STM_06	Created by experiment fraction entry (1926)	2010-01-19 12:18:03
1028	WP-1028	Fractions of GLBRC Ecoli for Formic Acid Database Creation	2010-02-01 10:19:07
1029	PNWRCE_RIGI_Spleen-1&2_SCX	PNWRCE_RIGI_Spleen-1 and 2 (25 fractions/sample)	2010-02-08 15:48:56
1030	PNWRCE_RIGI_Liver-3 and 4	PNWRCE_RIGI_Spleen-3 and 4 (25 fractions/sample)	2010-02-08 16:55:24
1031	WP-1031	MG_formic Fractions Plate 1	2010-02-26 15:14:46
1032	WP-1032	MG_formic Fractions Plate 2	2010-02-26 15:15:07
1033	WP-1033	MG_formic Fractions Plate 3	2010-02-26 15:15:26
1034	WP-1034	NR_formic Fractions Plate 1	2010-02-26 15:15:40
1035	1031	Created by experiment fraction entry (MG_formic_11)	2010-02-26 15:17:49
1036	1032	Created by experiment fraction entry (MG_formic_15)	2010-02-26 15:18:32
1037	WP-1037	SysVirol_MouseLung_AI_Mock_Pool1, SysVirol_MouseLung_AI_EarlyInf_Pool2, SysVirol_MouseLung_AI_LateInf_Pool3, , Request ID , 2399,	2010-02-26 15:30:48
1038	WP-1038	SysVirol_MouseLung_SARS_Mock_Pool1, SysVirol_MouseLung_SARS_EarlyInf_Pool2, SysVirol_MouseLung_SARS_LateInf_Pool3, , Request ID , 2400,	2010-02-26 15:31:26
1039	WP-1039	Baynes2SC Mouse Adipocyte Round 2	2010-03-04 10:43:17
1040	Gsulf801	Created by experiment fraction entry (Gsulf801)	2010-03-30 11:17:34
1041	GSulf802	Created by experiment fraction entry (Gsulf802)	2010-03-30 11:25:47
1042	GSulf803	Created by experiment fraction entry (Gsulf803)	2010-03-30 11:27:36
1043	GSulf804	Created by experiment fraction entry (Gsulf804)	2010-03-30 11:36:23
1044	GSulf805	Created by experiment fraction entry (Gsulf805)	2010-03-30 11:36:40
1045	GSulf806	Created by experiment fraction entry (Gsulf806)	2010-03-30 11:36:58
1046	SBEP_YPCO_018	Created by experiment fraction entry (SBEP_YPCO_018)	2010-04-02 14:43:52
1047	SBEP_YPCO_019	Created by experiment fraction entry (SBEP_YPCO_019)	2010-04-02 14:44:12
1048	SBEP_YPPF_010	Created by experiment fraction entry (SBEP_YPPF_010)	2010-04-02 14:44:46
1049	SBEP_YPPF_011	Created by experiment fraction entry (SBEP_YPPF_011)	2010-04-02 14:45:37
1050	SBEP_YSTB_010	Created by experiment fraction entry (SBEP_YSTB_010)	2010-04-02 14:46:11
1051	SBEP_YSTB_011	Created by experiment fraction entry (SBEP_YSTB_011)	2010-04-02 14:46:38
1052	WP-1052	LangBeat_Rcap Fractions Plate #1	2010-04-30 12:12:28
1053	WP-1053	LangBeat_Rcap Fractions Plate #2	2010-04-30 12:12:37
1054	WP-1054	Eco_48-WT&EtOH Fractions (SCXvsHpH; SequentialvsSmart pooling)	2010-05-25 14:40:40
1055	SysVirol_SCL005	Created by experiment fraction entry (SysVirol_SCL005_EarlyInfection_Pool_1)	2010-06-29 10:29:05
1056	WP-1056	SPE Precision Testing 1	2010-08-02 11:35:56
1057	WP-1057	SPE Precision Testing 2	2010-08-02 11:36:23
1058	WP-1058	SPE Precision Testing 3	2010-08-02 11:36:36
1059	1	Sarcopenia mini study	2010-08-03 08:30:42
1060	2	Sarcopenia mini study	2010-08-03 08:30:48
1061	Sarc_Base	Created by experiment fraction entry (Sarc_Base)	2010-08-03 08:53:52
1062	Sarc_Dev	Created by experiment fraction entry (Sarc_Dev)	2010-08-03 08:56:07
1063	NonSarc	Created by experiment fraction entry (Sarc_Non)	2010-08-03 08:56:31
1064	PNWRCE_Hum_Fibro	Created by experiment fraction entry (PNWRCE_Hum_Fibro)	2010-08-12 14:59:15
1065	HBC_P500	Created by experiment fraction entry (HBC_p500_P7_NC)	2010-08-12 15:50:24
1066	WP-1066	Thiocapsa marina High pH fractions	2010-08-13 09:04:32
1067	1066	Created by experiment fraction entry (Thio_D_G_pooled)	2010-08-13 10:17:20
1068	Yeast_UPS_6C	Created by experiment fraction entry (Yeast_UPS_6C)	2010-08-13 16:19:24
1069	PMoore_BJAB_EBV_Neg_2nd	Created by experiment fraction entry (Pmoore_BJAB_EBV_neg_2nd)	2010-08-20 15:19:47
1070	PMoore_RAJI_EBV_pos_2nd	Created by experiment fraction entry (Pmoore_RAJI_EBV_pos_2nd)	2010-08-20 15:20:32
1071	AFUM Fractions	Created by experiment fraction entry (Afum_Cyto)	2010-08-22 13:51:21
1072	SBEP_JCVI	Created by experiment fraction entry (SBEP_JCVI_Ctrl_Pool)	2010-09-21 16:17:39
1073	SBEP_C1	Created by experiment fraction entry (SBEP_C1_LPS_Pool)	2010-09-27 10:10:06
1074	SBEP_JCVI_C4	Created by experiment fraction entry (SBEP_JCVI_C4_Ctrl)	2010-11-09 12:29:40
1075	MSperm_Caput_Fluid	Created by experiment fraction entry (MSperm_Caput_Fluid)	2010-12-03 17:20:40
1076	MSperm_Cadua_Fluid	Created by experiment fraction entry (MSperm_Cauda_Fluid)	2010-12-03 17:21:19
1077	Aze_FX2P50	Created by experiment fraction entry (Aze_FX2P50_Global_Proteomics)	2010-12-03 17:22:35
1078	TM_Stat_Pools	Created by experiment fraction entry (TM_Stat_G_Pool)	2010-12-07 12:13:57
1079	TM_ML_Pools	Created by experiment fraction entry (TM_ML_G_Pool)	2010-12-07 12:28:29
1080	Tray_01	\N	2010-12-08 17:49:41
1081	Tray_02	\N	2010-12-08 17:49:46
1082	Cyano_B_Pool	Created by experiment fraction entry (Cyano_B_Pool)	2010-12-20 14:07:50
1083	Cel_FX2P53_Young	Created by experiment fraction entry (Cel_FX2P53_Young)	2010-12-20 14:35:50
1084	StenSkin_Fib	Created by experiment fraction entry (StenSkin_Fib)	2010-12-21 17:01:41
1085	StenSkin_Ker	Created by experiment fraction entry (StenSkin_Ker)	2010-12-21 17:01:57
1086	WSU_BF_PC_Pool	Created by experiment fraction entry (WSU_BF_PC_Pool)	2011-03-07 15:44:13
1087	Tgon_Pool	Created by experiment fraction entry (Tgon_LW_Pool)	2011-04-14 14:39:43
1088	Sarc_Dev2	Created by experiment fraction entry (Sarc_Non2)	2011-05-11 16:12:51
1089	NL_MT_Sol	Created by experiment fraction entry (NL_MT_Soluble)	2011-06-29 11:00:19
1090	EDRN_Cell_Pellet	Created by experiment fraction entry (EDRN_VCap_Pellet)	2011-07-12 08:41:42
1091	NCRR_PERS_POOL	Created by experiment fraction entry (NCRR_PERS_POOL)	2011-09-30 17:31:58
1092	RBAL_Pool_Con	Created by experiment fraction entry (RBAL_Pool_Con)	2011-09-30 18:02:07
1093	RBAL_Pool_Dust	Created by experiment fraction entry (RBAL_Pool_Dust)	2011-09-30 18:06:22
1094	RBAL_Pool	Created by experiment fraction entry (RBAL_Pool_Con)	2011-10-03 17:57:04
1095	WP-1095	Baynes2SC_Glu_HpH (_05 and _30)	2011-12-08 13:15:34
1096	WP-1096	XBridge_005_QCtest	2011-12-08 17:37:25
1097	Gbem_substrate_pool	SCX fractionation of Gbem_bulk/NP/FC/Fum pooled sample, experiment Gbem_substrate_pool	2012-03-07 09:04:06
1098	ND132_test_01	HpH fractions for global, soluble and insoluble prep used to test method on new organism.  Will be used to build database for AMT tag approach.	2012-03-07 14:48:49
1099	ALZ_Fractions	Created by experiment fraction entry (Alz_HPH_Frac)	2012-07-16 16:28:12
1100	Bhens_OM Samples	Created by experiment fraction entry (Bhens_OM_01)	2012-07-18 14:07:57
1101	GLBRC_iTRAQ4_LIMS318	A01-A12: GLBRC_iTRAQ4_LIMS318_T2_01-12; C01-C12: GLBRC_iTRAQ4_LIMS318_T3_01-12; E01-E12: GLBRC_iTRAQ4_LIMS318_T4_01-12; G01-G12: GLBRC_iTRAQ4_LIMS318_T5_01-12	2012-07-25 16:48:43
1102	GLBRC_iTRAQ4_LIMS320	A01-A12: GLBRC_iTRAQ4_LIMS320_T2_01-12; C01-C12: GLBRC_iTRAQ4_LIMS320_T3_01-12; E01-E12: GLBRC_iTRAQ4_LIMS320_T4_01-12; G01-G12: GLBRC_iTRAQ4_LIMS320_T5_01-12	2012-07-25 16:51:51
1103	GLBRC_iTRAQ4_LIMS327	A01-A12: GLBRC_iTRAQ4_LIMS327_T2_01-12; C01-C12: GLBRC_iTRAQ4_LIMS327_T3_01-12; E01-E12: GLBRC_iTRAQ4_LIMS327_T4_01-12; G01-G12: GLBRC_iTRAQ4_LIMS327_T5_01-12	2012-07-25 16:52:11
1104	Phototroph_iTRAQ4_2012-09	Comparison of photo and nonphoto lifestyles across three anoxygenic phototrophs	2012-09-19 16:19:15
1105	MRSA_iTRAQ	Created by experiment fraction entry (MRSA_Prot_iTRAQ)	2012-11-07 14:50:13
1106	Ernesto_RAW_AcetylProt_20130201	High pH reverse phase fractions of acetylated peptides from RAW cell lysates digested with Arg-C.	2013-02-01 10:11:02
1107	Sarwal_urine_plate_1	Sarwal_urine_plate_1	2013-02-06 14:53:30
1108	Sarwal_urine_plate_2	Sarwal_urine_plate_2	2013-02-06 14:53:36
1109	Sarwal_urine_plate_3	Sarwal_urine_plate_3	2013-02-06 14:53:41
1110	Sarwal_urine_plate_4	Sarwal_urine_plate_4	2013-02-06 14:53:45
1111	TCGA_QC	CPTAC TCGA samples for quality test	2013-02-07 13:06:20
1112	CompRef_QC	CPTAC CompRef samples for quality test	2013-02-07 13:06:42
1113	HURN_Iraq_urine	HURN_Iraq_urine	2013-03-14 15:16:15
1114	mhp_1	Desmond Smith hypothalamus study.  Main study plate 1 of 2	2013-04-22 14:33:57
1115	mhp_2	Desmond Smith hypothalamus study.  Main study plate 2 of 2	2013-04-22 14:34:07
1116	HURN_Iraq_wControls_urine	HURN Iraq urine with controls added	2013-04-24 13:46:41
1117	CTC_Mutants	Quantitatively compare mutant strains of Cyanobacterium. iTRAQ4 labeled fractions of 3 bio rep sets	2013-06-12 09:20:17
1118	Stegen_2013_1	\N	2013-06-13 11:33:46
1119	Stegen_2013_2	\N	2013-06-13 11:50:39
1120	Stegen_2013_3	\N	2013-06-13 11:50:42
1121	Stegen_2013_4	\N	2013-06-13 11:50:52
1122	mini_ctrl	Created by experiment fraction entry (mini_ctrl)	2013-09-16 08:32:15
1123	mini_hde	Created by experiment fraction entry (mini_hde)	2013-09-16 08:34:16
1124	mini_hdl	Created by experiment fraction entry (mini_hdl)	2013-09-16 08:34:31
1125	TB_Pools2_IMS	samples for TB serum database creation	2013-10-25 09:55:06
1126	CornStover_20131121	S85-23 Pellet and spent media	2013-11-21 11:40:19
1127	CPTAC_P6_IMS	48 fractions CompRef_P6	2014-04-11 15:08:21
1128	WCD003_WNVWT_pool	WCD003_WNVWT_pool	2014-04-22 09:36:50
1129	WCD003_Mock_pool	WCD003_Mock_pool	2014-04-22 09:37:16
1130	1128	Created by experiment fraction entry (OMICS_WCD003_WNVWT_Pool)	2014-04-22 09:39:29
1131	Dunlap_Nc_WT-C_TMT10_Set01-08	Dunlap_Nc_WT-C_TMT10_Set01-08	2014-05-09 15:10:31
1132	Dunlap_Nc_WT-C_TMT10_Set09-16	Dunlap_Nc_WT-C_TMT10_Set09-16	2014-05-09 15:10:48
1133	Dunlap_Nc_WT-C_TMT10_Set17-19	Dunlap_Nc_WT-C_TMT10_Set17-19	2014-05-09 15:10:57
1134	HLP_Oscar_D14P-48	Saline Lake - Oscar	2014-05-16 10:06:28
1135	WSM419_FreeLivingVSNodule_201406	Fraction sets for WSM419_FreeLiving_1-3 and WSM419_Nodule_1-3	2014-06-13 16:18:31
1136	TEDDY_DISCOVERY_SET_01	TEDDY_DISCOVERY_iTRAQ SET_01 RP fractions	2015-04-11 13:34:35
1137	TEDDY_DISCOVERY_SET_02	TEDDY_DISCOVERY_iTRAQ SET_02 RP fractions	2015-04-11 13:35:13
1138	TEDDY_DISCOVERY_SET_03	TEDDY_DISCOVERY_iTRAQ SET_03 RP fractions	2015-04-11 13:35:20
1139	TEDDY_DISCOVERY_SET_04	TEDDY_DISCOVERY_iTRAQ SET_04 RP fractions	2015-04-11 13:35:25
1140	TEDDY_DISCOVERY_SET_05	TEDDY_DISCOVERY_iTRAQ SET_05 RP fractions	2015-04-11 13:35:30
1141	TEDDY_DISCOVERY_SET_06	TEDDY_DISCOVERY_iTRAQ SET_06 RP fractions	2015-04-11 13:35:35
1142	TEDDY_DISCOVERY_SET_07	TEDDY_DISCOVERY_iTRAQ SET_07 RP fractions	2015-04-11 13:35:40
1143	TEDDY_DISCOVERY_SET_08	TEDDY_DISCOVERY_iTRAQ SET_08 RP fractions	2015-04-11 13:35:47
1144	TEDDY_DISCOVERY_SET_09	TEDDY_DISCOVERY_iTRAQ SET_09 RP fractions	2015-04-11 13:35:53
1145	TEDDY_DISCOVERY_SET_10	TEDDY_DISCOVERY_iTRAQ SET_10 RP fractions	2015-04-11 13:36:02
1146	Oscar_proSIP_Unamended	HpH fractions Oscar_proSIP_Unamended_15NO3_A and Oscar_proSIP_Unamended_13CO3_A	2015-04-21 14:35:19
1147	Oscar_proSIP_Amended	HpH fractions Oscar_proSIP_Amended_15NH4_A and Oscar_proSIP_Amended_13CO3_A	2015-04-21 14:42:28
1148	TEDDY_DISCOVERY_SET_11	TEDDY_DISCOVERY_iTRAQ SET_11 RP fractions	2015-05-06 16:04:56
1149	TEDDY_DISCOVERY_SET_12	TEDDY_DISCOVERY_iTRAQ SET_12 RP fractions	2015-05-06 16:05:03
1150	TEDDY_DISCOVERY_SET_13	TEDDY_DISCOVERY_iTRAQ SET_13 RP fractions	2015-05-06 16:05:10
1151	TEDDY_DISCOVERY_SET_14	TEDDY_DISCOVERY_iTRAQ SET_14 RP fractions	2015-05-06 16:05:16
1152	TEDDY_DISCOVERY_SET_15	TEDDY_DISCOVERY_iTRAQ SET_15 RP fractions	2015-05-06 16:05:22
1153	TEDDY_DISCOVERY_SET_16	TEDDY_DISCOVERY_iTRAQ SET_16 RP fractions	2015-05-06 16:05:27
1154	TEDDY_DISCOVERY_SET_17	TEDDY_DISCOVERY_iTRAQ SET_17 RP fractions	2015-05-06 16:05:31
1155	TEDDY_DISCOVERY_SET_18	TEDDY_DISCOVERY_iTRAQ SET_18 RP fractions	2015-05-06 16:05:37
1156	TEDDY_DISCOVERY_SET_19	TEDDY_DISCOVERY_iTRAQ SET_19 RP fractions	2015-05-06 16:05:42
1157	TEDDY_DISCOVERY_SET_20	TEDDY_DISCOVERY_iTRAQ SET_20 RP fractions	2015-05-06 16:05:51
1158	TEDDY_DISCOVERY_iTRAQ SET_11	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_11)	2015-05-06 16:11:59
1159	TEDDY_DISCOVERY_iTRAQ SET_12	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_12)	2015-05-06 16:21:33
1160	TEDDY_DISCOVERY_iTRAQ SET_13	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_13)	2015-05-06 16:29:01
1161	TEDDY_DISCOVERY_iTRAQ SET_14	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_14)	2015-05-06 16:30:11
1162	TEDDY_DISCOVERY_iTRAQ SET_15	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_15)	2015-05-06 16:31:05
1163	TEDDY_DISCOVERY_iTRAQ SET_16	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_16)	2015-05-06 16:31:55
1164	TEDDY_DISCOVERY_iTRAQ SET_17	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_17)	2015-05-06 16:35:23
1165	TEDDY_DISCOVERY_iTRAQ SET_18	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_18)	2015-05-06 16:36:16
1166	TEDDY_DISCOVERY_iTRAQ SET_19	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_19)	2015-05-06 16:37:16
1167	TEDDY_DISCOVERY_iTRAQ SET_20	Created by experiment fraction entry (TEDDY_DISCOVERY_SET_20)	2015-05-06 16:38:06
1168	TEDDY_DISCOVERY_iTRAQ SET_21_22	TEDDY_DISCOVERY_iTRAQ SET_21-22 RP fractions	2015-06-17 18:26:53
1169	TEDDY_DISCOVERY_iTRAQ SET_23_24	TEDDY_DISCOVERY_iTRAQ SET_23-24 RP fractions	2015-06-17 18:27:09
1170	TEDDY_DISCOVERY_iTRAQ SET_25_26	TEDDY_DISCOVERY_iTRAQ SET_25-26 RP fractions	2015-06-17 18:27:22
1171	TEDDY_DISCOVERY_iTRAQ SET_27_28	TEDDY_DISCOVERY_iTRAQ SET_27-28 RP fractions	2015-06-17 18:27:34
1172	TEDDY_DISCOVERY_iTRAQ SET_29_30	TEDDY_DISCOVERY_iTRAQ SET_29-30 RP fractions	2015-06-17 18:27:51
1173	TEDDY_DISCOVERY_iTRAQ SET_31	TEDDY_DISCOVERY_iTRAQ SET_31 RP fractions	2015-07-20 16:49:52
1174	TEDDY_DISCOVERY_iTRAQ SET_32	TEDDY_DISCOVERY_iTRAQ SET_32 RP fractions	2015-07-20 16:49:59
1175	TEDDY_DISCOVERY_iTRAQ SET_33	TEDDY_DISCOVERY_iTRAQ SET_33 RP fractions	2015-07-20 16:50:06
1176	TEDDY_DISCOVERY_iTRAQ SET_34	TEDDY_DISCOVERY_iTRAQ SET_34 RP fractions	2015-07-20 16:50:13
1177	TEDDY_DISCOVERY_iTRAQ SET_35	TEDDY_DISCOVERY_iTRAQ SET_35 RP fractions	2015-07-20 16:50:19
1178	TEDDY_DISCOVERY_iTRAQ SET_36	TEDDY_DISCOVERY_iTRAQ SET_36 RP fractions	2015-07-20 16:50:25
1179	TEDDY_DISCOVERY_iTRAQ SET_37	TEDDY_DISCOVERY_iTRAQ SET_37 RP fractions	2015-07-20 16:50:31
1180	TEDDY_DISCOVERY_iTRAQ SET_38	TEDDY_DISCOVERY_iTRAQ SET_38 RP fractions	2015-07-20 16:50:38
1181	TEDDY_DISCOVERY_iTRAQ SET_39	TEDDY_DISCOVERY_iTRAQ SET_39 RP fractions	2015-07-20 16:50:44
1182	TEDDY_DISCOVERY_iTRAQ SET_40	TEDDY_DISCOVERY_iTRAQ SET_40 RP fractions	2015-07-20 16:50:53
1183	OHSU_SRM_Set1	OHSU Plasma Samples from SRM, Samples 1-60	2015-07-31 13:36:28
1184	OHSU_SRM_Set2	OHSU Plasma Samples from SRM, Samples 61-120	2015-07-31 13:36:45
1185	TEDDY_DISCOVERY_iTRAQ SET_41	TEDDY_DISCOVERY_iTRAQ SET_41 RP fractions	2015-10-13 12:18:23
1186	TEDDY_DISCOVERY_iTRAQ SET_42	TEDDY_DISCOVERY_iTRAQ SET_42 RP fractions	2015-10-13 12:18:30
1187	TEDDY_DISCOVERY_iTRAQ SET_43	TEDDY_DISCOVERY_iTRAQ SET_43 RP fractions	2015-10-13 12:18:36
1188	TEDDY_DISCOVERY_iTRAQ SET_44	TEDDY_DISCOVERY_iTRAQ SET_44 RP fractions	2015-10-13 12:18:43
1189	TEDDY_DISCOVERY_iTRAQ SET_45	TEDDY_DISCOVERY_iTRAQ SET_45 RP fractions	2015-10-13 12:18:49
1190	TEDDY_DISCOVERY_iTRAQ SET_46	TEDDY_DISCOVERY_iTRAQ SET_46 RP fractions	2015-10-13 12:18:56
1191	TEDDY_DISCOVERY_iTRAQ SET_47	TEDDY_DISCOVERY_iTRAQ SET_47 RP fractions	2015-10-13 12:19:01
1192	TEDDY_DISCOVERY_iTRAQ SET_48	TEDDY_DISCOVERY_iTRAQ SET_48 RP fractions	2015-10-13 12:19:07
1193	TEDDY_DISCOVERY_iTRAQ SET_49	TEDDY_DISCOVERY_iTRAQ SET_49 RP fractions	2015-10-13 12:19:13
1194	TEDDY_DISCOVERY_iTRAQ SET_50	TEDDY_DISCOVERY_iTRAQ SET_50 RP fractions	2015-10-13 12:19:21
1195	TEDDY_DISCOVERY_iTRAQ SET_51	TEDDY_DISCOVERY_iTRAQ SET_51 RP fractions	2015-11-30 15:48:44
1196	TEDDY_DISCOVERY_iTRAQ SET_52	TEDDY_DISCOVERY_iTRAQ SET_52 RP fractions	2015-11-30 15:48:52
1197	TEDDY_DISCOVERY_iTRAQ SET_53	TEDDY_DISCOVERY_iTRAQ SET_53 RP fractions	2015-11-30 15:48:59
1198	TEDDY_DISCOVERY_iTRAQ SET_54	TEDDY_DISCOVERY_iTRAQ SET_54 RP fractions	2015-11-30 15:49:10
1199	TEDDY_DISCOVERY_iTRAQ SET_55	TEDDY_DISCOVERY_iTRAQ SET_55 RP fractions	2015-11-30 15:49:17
1200	TEDDY_DISCOVERY_iTRAQ SET_56	TEDDY_DISCOVERY_iTRAQ SET_56 RP fractions	2015-11-30 15:49:24
1201	TEDDY_DISCOVERY_iTRAQ SET_57	TEDDY_DISCOVERY_iTRAQ SET_57 RP fractions	2015-12-15 10:29:42
1202	TEDDY_DISCOVERY_iTRAQ SET_58	TEDDY_DISCOVERY_iTRAQ SET_58 RP fractions	2015-12-15 10:29:51
1203	TEDDY_DISCOVERY_iTRAQ SET_59	TEDDY_DISCOVERY_iTRAQ SET_59 RP fractions	2015-12-15 10:29:57
1204	TEDDY_DISCOVERY_iTRAQ SET_60	TEDDY_DISCOVERY_iTRAQ SET_60 RP fractions	2015-12-15 10:30:07
1205	TEDDY_DISCOVERY_iTRAQ SET_61	TEDDY_DISCOVERY_iTRAQ SET_61 RP fractions	2015-12-15 10:30:14
1206	TEDDY_DISCOVERY_iTRAQ SET_62	TEDDY_DISCOVERY_iTRAQ SET_62 RP fractions	2015-12-15 10:30:22
1207	PVN_N_Peptides	Peptide samples from PVN_N digestion - 40 samples	2017-03-01 13:31:29
1208	PVN_Q Peptides	Stored at 1208B.1.4.1.4, 60 samples	2017-06-05 21:00:35
1209	iPASS_Metab_01	Plate #1 of iPASS Metabolites	2017-08-31 20:52:07
1210	iPASS_Metab_02	Plate #2 of iPASS Metabolites	2017-08-31 20:52:19
1211	iPASS_Metab_03	Plate #3 of iPASS Metabolites	2017-08-31 20:52:38
1212	EPICON_Metab_Set1_Plate1	First plate of Metabolites for first set of EPICON Sorghum drought samples	2017-09-06 10:32:20
1213	EPICON_Metab_Set1_Plate2	Second plate of Metabolites for first set of EPICON Sorghum drought samples	2017-09-06 10:32:30
1214	EPICON_Metab_Set1_Plate3	Third plate of Metabolites for first set of EPICON Sorghum drought samples	2017-09-06 10:32:43
1215	EPICON_Metab_Set1_Plate4	Fourth plate of Metabolites for first set of EPICON Sorghum drought samples	2017-09-06 10:32:52
1216	IROA_Plate_01	IROA Standards Plate 1 (10 uM concentration)	2018-01-19 06:05:44
1217	IROA_Plate_02	IROA Standards Plate 2 (10 uM concentration)	2018-01-19 06:05:53
1218	IROA_Plate_03	IROA Standards Plate 3 (10 uM concentration)	2018-01-19 06:06:01
1219	IROA_Plate_04	IROA Standards Plate 4 (10 uM concentration)	2018-01-19 06:06:09
1220	IROA_Plate_05	IROA Standards Plate 5 (10 uM concentration)	2018-01-19 06:06:17
1221	IROA_Plate_06	IROA Standards Plate 6 (10 uM concentration)	2018-01-19 06:06:24
1222	IROA_Plate_07	IROA Standards Plate 7 (10 uM concentration)	2018-01-19 06:06:31
1223	CPTAC3_Pilot_pSTY	test pp from 50 ug starting material	2018-02-01 11:01:30
1224	TEDDY_Linearity	Linearity samples for TEDDY validation prep	2018-03-02 10:25:15
1225	TEDDY_Val_B1_P1	TEDDY Validation Phase Shipment Batch 1 Plate 1	2018-03-02 10:25:43
1226	TEDDY_Val_B1_P2	TEDDY Validation Phase Shipment Batch 1 Plate 2	2018-03-02 10:25:51
1227	TEDDY_Val_B1_P3	TEDDY Validation Phase Shipment Batch 1 Plate 3	2018-05-25 12:35:25
1228	TEDDY_Val_B1_P4	TEDDY Validation Phase Shipment Batch 1 Plate 4	2018-05-25 12:35:33
1229	TEDDY_Val_B1_P5	TEDDY Validation Phase Shipment Batch 1 Plate 5	2018-05-31 13:09:14
1230	TEDDY_Val_B1_P6	TEDDY Validation Phase Shipment Batch 1 Plate 6	2018-05-31 13:09:22
1231	TEDDY_Val_B1_P7	TEDDY Validation Phase Shipment Batch 1 Plate 7	2018-06-28 06:25:20
1232	TEDDY_Val_B1_P8	TEDDY Validation Phase Shipment Batch 1 Plate 8	2018-06-28 07:20:16
1233	TEDDY_Val_B2_P09	TEDDY Validation Phase Shipment Batch 2 Plate 9	2018-06-28 08:14:12
1234	TEDDY_Val_B2_P10	TEDDY Validation Phase Shipment Batch 2 Plate 10	2018-06-28 08:52:36
1235	TEDDY_Val_B2_P11	TEDDY Validation Phase Shipment Batch 2 Plate 11	2018-07-23 08:16:16
1236	TEDDY_Val_B2_P12	TEDDY Validation Phase Shipment Batch 2 Plate 12	2018-07-23 08:16:23
1237	MNST_Plate_01	Moonshot Digested FT Peptides Plate 01	2018-08-02 12:17:00
1238	TEDDY_Val_B2_P13	TEDDY Validation Phase Shipment Batch 2 Plate 13	2018-08-15 12:07:03
1239	TEDDY_Val_B2_P14	TEDDY Validation Phase Shipment Batch 2 Plate 14	2018-08-15 12:07:13
1240	TEDDY_Val_B2_P15	TEDDY Validation Phase Shipment Batch 2 Plate 15	2018-08-15 12:07:20
1241	TEDDY_Val_B2_P16	TEDDY Validation Phase Shipment Batch 2 Plate 16	2018-08-15 12:07:27
1242	MNST_Plate_02	Moonshot Digested FT Peptides Plate 02	2018-08-21 06:02:29
1243	TEDDY_Val_B3_P17	TEDDY Validation Phase Shipment Batch 3 Plate 17	2018-10-29 11:50:08
1244	TEDDY_Val_B4_P25	TEDDY Validation Phase Shipment Batch 4 Plate 25	2019-02-07 13:09:21
1245	TEDDY_Val_B4_P26	TEDDY Validation Phase Shipment Batch 4 Plate 26	2019-02-07 13:13:47
1246	TEDDY_Val_B4_P27	TEDDY Validation Phase Shipment Batch 4 Plate 27	2019-02-07 13:32:31
1247	TEDDY_Val_B4_P28	TEDDY Validation Phase Shipment Batch 4 Plate 28	2019-02-07 13:32:39
1248	TEDDY_Val_B4_P29	TEDDY Validation Phase Shipment Batch 4 Plate 29	2019-03-28 05:39:14
1249	TEDDY_Val_B4_P30	TEDDY Validation Phase Shipment Batch 4 Plate 30	2019-03-28 05:39:22
1250	TEDDY_Val_B4_P31	TEDDY Validation Phase Shipment Batch 4 Plate 31	2019-03-28 05:39:29
1251	TEDDY_Val_B4_P32	TEDDY Validation Phase Shipment Batch 4 Plate 32	2019-03-28 05:39:36
1252	PNACIC_EPA_Plate_01	PNACIC_EPA_Plate_01 (Shipment Plate TP0001862 A01-D24)	2019-03-28 11:14:50
1253	PNACIC_EPA_Plate_02	PNACIC_EPA_Plate_02 (Shipment Plate TP0001862 E01-H24)	2019-03-28 15:35:18
1254	PNACIC_EPA_Plate_03	PNACIC_EPA_Plate_03 (Shipment Plate TP0001862 I01-L24)	2019-03-28 15:35:35
1255	PNACIC_EPA_Plate_04	PNACIC_EPA_Plate_04 (Shipment Plate TP0001862 M01-P24)	2019-03-28 15:35:51
1256	PNACIC_EPA_Plate_05	PNACIC_EPA_Plate_05 (Shipment Plate TP0001863 A01-D24)	2019-03-29 15:46:58
1257	PNACIC_EPA_Plate_06	PNACIC_EPA_Plate_06 (Shipment Plate TP0001863 E01-H24)	2019-03-29 15:47:18
1258	PNACIC_EPA_Plate_07	PNACIC_EPA_Plate_07 (Shipment Plate TP0001863 I01-L24)	2019-03-29 15:47:34
1259	PNACIC_EPA_Plate_08	PNACIC_EPA_Plate_08 (Shipment Plate TP0001863 M01-P24)	2019-03-29 15:47:53
1260	PNACIC_EPA_Plate_09	PNACIC_EPA_Plate_09 (Shipment Plate TP0001864 A01-D24)	2019-04-02 06:54:13
1261	PNACIC_EPA_Plate_10	PNACIC_EPA_Plate_10 (Shipment Plate TP0001864 E01-H24)	2019-04-02 06:54:28
1262	PNACIC_EPA_Plate_11	PNACIC_EPA_Plate_11 (Shipment Plate TP0001864 I01-L24)	2019-04-02 06:54:43
1263	PNACIC_EPA_Plate_12	PNACIC_EPA_Plate_12 (Shipment Plate TP0001864 M01-P24)	2019-04-02 06:55:01
1264	PNACIC_EPA_Plate_13	PNACIC_EPA_Plate_13 (Shipment Plate TP0001865 A01-D24)	2019-04-04 19:45:30
1265	PNACIC_EPA_Plate_14	PNACIC_EPA_Plate_14 (Shipment Plate TP0001865 E01-H24)	2019-04-04 19:45:48
1266	PNACIC_EPA_Plate_15	PNACIC_EPA_Plate_15 (Shipment Plate TP0001865 I01-L24)	2019-04-04 19:46:06
1267	PNACIC_EPA_Plate_16	PNACIC_EPA_Plate_16 (Shipment Plate TP0001865 M01-P24)	2019-04-04 19:46:22
1268	PNACIC_EPA_Plate_17	PNACIC_EPA_Plate_17 (Shipment Plate TP0001866 A01-D24)	2019-04-04 19:46:46
1269	PNACIC_EPA_Plate_18	PNACIC_EPA_Plate_18 (Shipment Plate TP0001866 E01-H24)	2019-04-04 19:47:02
1270	PNACIC_EPA_Plate_19	PNACIC_EPA_Plate_19 (Shipment Plate TP0001866 I01-L24)	2019-04-04 19:47:17
1271	PNACIC_EPA_Plate_20	PNACIC_EPA_Plate_20 (Shipment Plate TP0001866 M01-P24)	2019-04-04 19:47:33
1272	PNACIC_EPA_Plate_21	PNACIC_EPA_Plate_21 (Shipment Plate TP0001867 A01-D24)	2019-04-04 19:47:51
1273	PNACIC_EPA_Plate_22	PNACIC_EPA_Plate_22 (Shipment Plate TP0001867 E01-H24)	2019-04-04 19:48:06
1274	PNACIC_EPA_Plate_23	PNACIC_EPA_Plate_23 (Shipment Plate TP0001867 I01-L24)	2019-04-04 19:48:23
1275	PNACIC_EPA_Plate_24	PNACIC_EPA_Plate_24 (Shipment Plate TP0001867 M01-P24)	2019-04-04 19:48:38
1276	TEDDY_Val_B5_P33	TEDDY Validation Phase Shipment Batch 5 Plate 33	2019-05-01 18:55:06
1277	TEDDY_Val_B5_P34	TEDDY Validation Phase Shipment Batch 5 Plate 34	2019-05-01 18:55:14
1278	TEDDY_Val_B5_P35	TEDDY Validation Phase Shipment Batch 5 Plate 35	2019-05-01 18:55:22
1279	TEDDY_Val_B5_P36	TEDDY Validation Phase Shipment Batch 5 Plate 36	2019-05-01 18:55:34
1280	PNACIC_EPA_Plate_25	PNACIC_EPA_Plate_25 (Shipment Plate TP0001868 A01-D24)	2019-05-04 07:38:59
1281	PNACIC_EPA_Plate_26	PNACIC_EPA_Plate_26 (Shipment Plate TP0001868 E01-H24)	2019-05-04 07:39:14
1282	PNACIC_EPA_Plate_27	PNACIC_EPA_Plate_27 (Shipment Plate TP0001868 I01-L24)	2019-05-04 07:39:34
1283	PNACIC_EPA_Plate_28	PNACIC_EPA_Plate_28 (Shipment Plate TP0001868 M01-P24)	2019-05-04 07:39:51
1284	PNACIC_EPA_Plate_29	PNACIC_EPA_Plate_29 (Shipment Plate TP0001869 A01-D24)	2019-05-05 09:48:04
1285	PNACIC_EPA_Plate_30	PNACIC_EPA_Plate_30 (Shipment Plate TP0001869 E01-H24)	2019-05-05 09:48:17
1286	PNACIC_EPA_Plate_31	PNACIC_EPA_Plate_31 (Shipment Plate TP0001869 I01-L24)	2019-05-05 09:48:32
1287	PNACIC_EPA_Plate_32	PNACIC_EPA_Plate_32 (Shipment Plate TP0001869 M01-P24)	2019-05-05 09:48:45
1288	PNACIC_EPA_Plate_33	PNACIC_EPA_Plate_33 (Shipment Plate TP0001870 A01-D24)	2019-05-09 06:36:28
1289	PNACIC_EPA_Plate_34	PNACIC_EPA_Plate_34 (Shipment Plate TP0001870 E01-H24)	2019-05-09 06:36:42
1290	PNACIC_EPA_Plate_35	PNACIC_EPA_Plate_35 (Shipment Plate TP0001870 I01-L24)	2019-05-09 06:37:01
1291	PNACIC_EPA_Plate_36	PNACIC_EPA_Plate_36 (Shipment Plate TP0001870 M01-P24)	2019-05-09 06:37:16
1292	TEDDY_Val_B5_P37	TEDDY Validation Phase Shipment Batch 5 Plate 37	2019-06-05 08:15:38
1293	TEDDY_Val_B5_P38	TEDDY Validation Phase Shipment Batch 5 Plate 38	2019-06-05 08:15:45
1294	TEDDY_Val_B5_P39	TEDDY Validation Phase Shipment Batch 5 Plate 39	2019-06-05 08:15:51
1295	TEDDY_Val_B5_P40	TEDDY Validation Phase Shipment Batch 5 Plate 40	2019-06-05 08:15:58
1296	OMICS_Zika_plas_Plate1	OMICS Zika FT plasma digested samples Plate 1	2019-08-19 12:55:25
1297	OMICS_Zika_plas_Plate2	OMICS Zika FT plasma digested samples Plate 2	2019-08-19 12:55:32
1298	TEDDY_Val_B6_P41	TEDDY Validation Phase Shipment Batch 6 Plate 41	2019-08-21 06:46:23
1299	TEDDY_Val_B6_P42	TEDDY Validation Phase Shipment Batch 6 Plate 42	2019-08-21 06:46:31
1300	TEDDY_Val_B6_P43	TEDDY Validation Phase Shipment Batch 6 Plate 43	2019-08-21 06:46:38
1301	TEDDY_Val_B6_P44	TEDDY Validation Phase Shipment Batch 6 Plate 44	2019-08-21 06:46:44
1302	TEDDY_Val_B6_P45	TEDDY Validation Phase Shipment Batch 6 Plate 45	2019-08-21 06:46:51
1303	TEDDY_Val_B6_P46	TEDDY Validation Phase Shipment Batch 6 Plate 46	2019-08-21 06:46:57
1304	TEDDY_Val_B6_P47	TEDDY Validation Phase Shipment Batch 6 Plate 47	2019-09-20 13:46:03
1305	TEDDY_Val_B6_P48	TEDDY Validation Phase Shipment Batch 6 Plate 48	2019-09-20 13:46:10
1306	DAISY_P01	DAISY Plate 01	2019-09-30 07:08:06
1307	DAISY_P02	DAISY Plate 02	2019-09-30 07:08:13
1308	IROA_Set2_Plate_01	IROA Standards Plate 1 (Stock solutions, 100 uM or 500 uM)	2019-10-04 09:53:22
1309	IROA_Set2_Plate_02	IROA Standards Plate 2 (Stock solutions, 100 uM or 500 uM)	2019-10-04 09:53:31
1310	IROA_Set2_Plate_03	IROA Standards Plate 3 (Stock solutions, 100 uM or 500 uM)	2019-10-07 10:59:07
1311	IROA_Set2_Plate_04	IROA Standards Plate 4 (Stock solutions, 100 uM or 500 uM)	2019-10-07 10:59:15
1312	IROA_Set2_Plate_05	IROA Standards Plate 5 (Stock solutions, 100 uM or 500 uM)	2019-10-07 10:59:22
1313	TEDDY_Val_B7_P49	TEDDY Validation Phase Shipment Batch 7 Plate 49	2019-10-07 10:59:46
1314	TEDDY_Val_B7_P50	TEDDY Validation Phase Shipment Batch 7 Plate 50	2019-10-07 10:59:53
1315	TEDDY_Val_B7_P51	TEDDY Validation Phase Shipment Batch 7 Plate 51	2019-10-07 11:00:00
1316	TEDDY_Val_B7_P52	TEDDY Validation Phase Shipment Batch 7 Plate 52	2019-10-07 11:00:07
1317	DAISY_P03	DAISY Plate 03	2019-10-22 08:46:26
1318	DAISY_P04	DAISY Plate 04	2019-10-22 08:46:34
1319	DAISY_P05	DAISY Plate 05	2019-10-22 08:46:40
1320	DAISY_P06	DAISY Plate 06	2019-10-22 08:46:47
1321	IROA_Set2_Plate_06	IROA Standards Plate 6 (Stock solutions, 100 uM or 500 uM)	2019-11-12 12:04:29
1322	IROA_Set2_Plate_07	IROA Standards Plate 7 (Stock solutions, 100 uM or 500 uM)	2019-11-12 12:04:36
1323	TEDDY_Val_B7_P53	TEDDY Validation Phase Shipment Batch 7 Plate 53	2019-12-18 13:31:11
1324	TEDDY_Val_B7_P54	TEDDY Validation Phase Shipment Batch 7 Plate 54	2019-12-18 13:31:17
1325	TEDDY_Val_B7_P55	TEDDY Validation Phase Shipment Batch 7 Plate 55	2019-12-18 13:31:24
1326	TEDDY_Val_B7_P56	TEDDY Validation Phase Shipment Batch 7 Plate 56	2019-12-18 13:31:32
1327	EPICON_Baker_09_Low_Org	EPICON Baker Metabolites 09 Collection Data Leaf, Root, Stem Low Organic	2020-02-06 13:29:38
1328	EPICON_Baker_09_Hi_Org	EPICON Baker Metabolites 09 Collection Data Leaf, Root, Stem Hi Organic	2020-02-11 10:29:38
1329	EPICON_Baker_23_Low_Org	EPICON Baker Metabolites 23 Collection Data Leaf, Root, Stem Low Organic	2020-02-11 10:34:03
1330	EPICON_Baker_23_Hi_Org	EPICON Baker Metabolites 23 Collection Data Leaf, Root, Stem High Organic	2020-02-11 10:34:18
1331	EPICON_Baker_26_Low_Org	EPICON Baker Metabolites 26 Collection Data Leaf, Root, Stem Low Organic	2020-02-11 10:34:33
1332	EPICON_Baker_26_Hi_Org	EPICON Baker Metabolites 26 Collection Data Leaf, Root, Stem High Organic	2020-02-11 10:34:42
1333	NLewis_Met_Leaf_Low_Org	NLewis Metabolites Leaf Low Organic	2020-02-11 14:03:47
1334	NLewis_Met_Leaf_High_Org	NLewis Metabolites Leaf High Organic	2020-02-11 14:03:58
1335	NLewis_Met_Stem_Low_Org	NLewis Metabolites Stem Low Organic	2020-02-11 14:04:13
1336	NLewis_Met_Stem_Hi_Org	NLewis Metabolites Stem High Organic	2020-02-11 14:04:22
1337	TEDDY_Val_B8_P57	TEDDY Validation Phase Shipment Batch 8 Plate 57	2020-03-09 08:35:49
1338	TEDDY_Val_B8_P58	TEDDY Validation Phase Shipment Batch 8 Plate 58	2020-03-09 08:36:00
1339	TEDDY_Val_B8_P59	TEDDY Validation Phase Shipment Batch 8 Plate 59	2020-03-09 08:36:08
1340	TEDDY_Val_B8_P60	TEDDY Validation Phase Shipment Batch 8 Plate 60	2020-03-09 08:36:18
1341	TEDDY_Val_B8_P61	TEDDY Validation Phase Shipment Batch 8 Plate 61	2020-04-27 11:45:36
1342	TEDDY_Val_B8_P62	TEDDY Validation Phase Shipment Batch 8 Plate 62	2020-04-27 11:45:43
1343	TEDDY_Val_B8_P63	TEDDY Validation Phase Shipment Batch 8 Plate 63	2020-04-27 11:45:51
1344	TEDDY_Val_B8_P64	TEDDY Validation Phase Shipment Batch 8 Plate 64	2020-04-27 11:45:58
1345	DAISY_P07	DAISY Plate 07	2020-05-22 09:44:10
1346	DAISY_P08	DAISY Plate 08	2020-05-22 09:44:16
1347	DAISY_P09	DAISY Plate 09	2020-05-22 09:44:24
1348	DAISY_P10	DAISY Plate 10	2020-05-22 09:44:34
1349	TEDDY_Val_B9_P65	TEDDY Validation Phase Shipment Batch 9 Plate 65	2020-06-26 09:18:12
1350	TEDDY_Val_B9_P66	TEDDY Validation Phase Shipment Batch 9 Plate 66	2020-06-26 09:18:20
1351	TEDDY_Val_B9_P67	TEDDY Validation Phase Shipment Batch 9 Plate 67	2020-06-26 09:18:27
1352	TEDDY_Val_B9_P68	TEDDY Validation Phase Shipment Batch 9 Plate 68	2020-06-26 09:18:34
1353	TEDDY_Val_B9_P69	TEDDY Validation Phase Shipment Batch 9 Plate 69	2020-07-22 10:29:30
1354	TEDDY_Val_B9_P70	TEDDY Validation Phase Shipment Batch 9 Plate 70	2020-07-22 10:29:39
1355	TEDDY_Val_B9_P71	TEDDY Validation Phase Shipment Batch 9 Plate 71	2020-07-22 10:29:48
1356	TEDDY_Val_B9_P72	TEDDY Validation Phase Shipment Batch 9 Plate 72	2020-07-22 10:29:56
1357	TEDDY_Val_B10_P73	TEDDY Validation Phase Shipment Batch 10 Plate 73	2020-08-24 10:32:17
1358	TEDDY_Val_B10_P74	TEDDY Validation Phase Shipment Batch 10 Plate 74	2020-08-24 10:32:27
1359	TEDDY_Val_B10_P75	TEDDY Validation Phase Shipment Batch 10 Plate 75	2020-08-24 10:32:33
1360	TEDDY_Val_B10_P76	TEDDY Validation Phase Shipment Batch 10 Plate 76	2020-08-24 10:32:40
1361	TEDDY_Val_B10_P77	TEDDY Validation Phase Shipment Batch 10 Plate 77	2020-09-24 10:31:34
1362	TEDDY_Val_B10_P78	TEDDY Validation Phase Shipment Batch 10 Plate 78	2020-09-24 10:31:41
1363	TEDDY_Val_B10_P79	TEDDY Validation Phase Shipment Batch 10 Plate 79	2020-09-24 10:31:48
1364	TEDDY_Val_B10_P80	TEDDY Validation Phase Shipment Batch 10 Plate 80	2020-09-24 10:31:55
1365	Muscle_Mock_TMT16	Created by experiment fraction entry (Muscle_Mock_TMT16)	2021-01-13 14:56:11
1366	Cpep_Sinai	Cpeptide prep of Mt Sinai samples and calibrators	2021-02-22 11:24:14
1367	Obesity_96SOP_P2	Prep 2 of Obesity 96-well plate, testing SOP	2021-09-02 13:11:53
1368	A2CPS Initial Test Plate	Initial prep plate of A2CPS/Pain samples (23 samples). 5 ul plasma processed (non-depleted)	2021-10-06 07:39:55
1369	MNST-2A_DSC_P1	Moonshot-2A Discovery Plate 1	2021-12-01 07:32:13
1370	MNST-2A_DSC_P2	Moonshot-2A Discovery Plate 2	2021-12-01 07:32:20
1371	TB3_CURED1_TF00065439	TBSmart; Cured_01 (Visit 00) - Plate Barcode TF00065439 - digests for SRM	2021-12-11 15:13:23
1372	TB3_CURED2_TF00065434	TBSmart; Cured_02 (Visit 02) - Plate Barcode TF00065434 - digests for SRM	2021-12-11 15:14:08
1373	TB3_CURED3_TF00061356	TBSmart; Cured_03 (Visit 03) - Plate Barcode TF00061356 - digests for SRM	2021-12-11 15:14:42
1374	TB3_CURED4_TF00061349	TBSmart; Cured_04 (Visit 08) - Plate Barcode TF00061349 - digests for SRM	2021-12-11 15:15:16
1375	TB3_CURED5_TF00040666	TBSmart; Cured_05 (Visit 17) - Plate Barcode TF00040666 - digests for SRM	2021-12-11 15:15:53
1376	TB3_CURED6_TF00040734	TBSmart; Cured_06 (Visit 26) - Plate Barcode TF00040734 - digests for SRM	2021-12-11 15:16:29
1377	TB3_CURED7_TF00040810	TBSmart; Cured_07 (Visit 52) - Plate Barcode TF00040810 - digests for SRM	2021-12-11 15:17:08
1378	TB3_REMOX1_TS01244530	TBSmart; REMOX_01 (relapsed, all data points) - Plate Barcode TS01244530, contains two samples from TS01244555 - digests for SRM	2021-12-11 15:21:13
1379	TB3_NTP1_TS01244547	TBSmart; NTP_01 (relapsed, 00,02,04 data points) - Plate Barcode TS01244547 - digests for SRM	2021-12-11 15:22:22
1380	TB3_NTP2_TS01244533	TBSmart; NTP_02 (relapsed, 04,08,17 data points) - Plate Barcode TS01244533 - digests for SRM	2021-12-11 15:23:15
1381	TB3_NTP3_TS01244541	TBSmart; NTP_03 (relapsed, 17,26,52 data points) - Plate Barcode TS01244541 - digests for SRM	2021-12-11 15:24:08
1382	TB3_NTP4_TS01244544	TBSmart; NTP_04 (relapsed, 52 data points and WD) - Plate Barcode TS01244544 - digests for SRM	2021-12-11 15:24:52
1383	MNST-3_DSC	Moonshot-3 Discovery Digested Peptides	2021-12-27 11:15:57
1384	Tafesse_Peptides	Digested peptides from Tafesse prep	2022-01-07 07:48:42
1385	Smallwood_Plasma_Peptides	Digested peptides from Smallwood lab	2022-03-14 10:42:23
1386	Smallwood_NRF_Peptides	Digested peptides from Smallwood lab	2022-03-14 10:42:33
1387	Obesity_459Prep_P1	Prep of 459 Obesity samples, Plate 1	2022-04-27 14:20:16
1388	Obesity_459Prep_P2	Prep of 459 Obesity samples, Plate 2	2022-04-27 14:20:23
1389	Obesity_459Prep_P3	Prep of 459 Obesity samples, Plate 3	2022-04-27 14:20:30
1390	Obesity_459Prep_P5	Prep of 459 Obesity samples, Plate 5	2022-04-27 14:20:45
1391	Obesity_459Prep_P6	Prep of 459 Obesity samples, Plate 6	2022-04-27 14:20:52
1392	Obesity_459Prep_P4	Prep of 459 Obesity samples, Plate 4	2022-04-27 14:21:06
1393	MNST-4_SRM_P01	Moonshot-4 SRM Digested Peptides - Plate 1	2022-06-14 08:46:22
1394	MNST-4_SRM_P02	Moonshot-4 SRM Digested Peptides - Plate 2	2022-06-14 08:46:29
1395	MNST-4_SRM_P03	Moonshot-4 SRM Digested Peptides - Plate 3	2022-07-06 06:35:45
1396	A2CPS_Plate1	A2CPS Digested Peptides - Plate 1	2022-07-27 12:59:11
1397	A2CPS_Plate2	A2CPS Digested Peptides - Plate 2	2022-07-27 12:59:18
1398	A2CPS_Plate3	A2CPS Digested Peptides - Plate 3	2022-07-27 12:59:23
1399	A2CPS_Plate4	A2CPS Digested Peptides - Plate 4	2022-07-27 12:59:30
1400	A2CPS_Plate5	A2CPS Digested Peptides - Plate 5	2023-05-03 08:51:22
1401	A2CPS_Plate6	A2CPS Digested Peptides - Plate 6	2023-05-03 09:03:09
1402	A2CPS_Plate7	A2CPS Digested Peptides - Plate 7	2023-05-23 08:13:08
1403	A2CPS_Plate8	A2CPS Digested Peptides - Plate 8	2023-05-23 08:13:15
1404	A2CPS_Plate9	A2CPS Digested Peptides - Plate 9	2023-05-23 08:13:21
1405	OHSU_mac_Plate1	OHSU_mac Digested Peptides - Plate 1	2023-07-18 13:25:32
1406	OHSU_mac_Plate2	OHSU_mac Digested Peptides - Plate 2	2023-07-18 13:25:38
1407	OHSU_mac_Plate3	OHSU_mac Digested Peptides - Plate 3	2023-07-18 13:25:45
1408	OHSU_mac_Plate4	OHSU_mac Digested Peptides - Plate 4	2023-07-18 13:25:52
1409	OHSU_mac_Plate5	OHSU_mac Digested Peptides - Plate 5	2023-07-18 13:25:58
1410	Exo_Laurent_Plate1	Timecourse, Non-Pregnant Plasma 200 ug	2023-09-25 10:40:37
1411	Exo_Laurent_Plate2	PES, Non-Pregnant Plasma >50 ug	2023-09-25 10:40:56
1412	Exo_Laurent_Plate3	SEC-Izon-DiFi Peptide plate	2023-09-25 10:49:48
1413	A2CPS_Plate10	A2CPS Digested Peptides - Plate 10	2023-09-25 12:34:14
1414	A2CPS_Plate11	A2CPS Digested Peptides - Plate 11	2023-09-25 12:34:21
1415	A2CPS_Plate12	A2CPS Digested Peptides - Plate 12	2023-09-25 12:34:29
1416	A2CPS_Plate13	A2CPS Digested Peptides - Plate 13	2023-09-25 12:34:36
1417	A2CPS_Plate14	A2CPS Digested Peptides - Plate 14	2023-09-25 12:34:43
1418	OHSU_mac_Prep3_Plate1	OHSU_mac Digested Peptides Prep 3 (Nov 2023) - Plate 1	2023-12-06 14:20:26
1419	OHSU_mac_Prep3_Plate2	OHSU_mac Digested Peptides Prep 3 (Nov 2023) - Plate 2	2023-12-06 14:20:34
1420	OHSU_mac_Prep3_Plate3	OHSU_mac Digested Peptides Prep 3 (Nov 2023) - Plate 3	2023-12-06 14:20:41
1421	OHSU_mac_Prep4_Plate	OHSU_mac Digested Peptides Prep 4 (Feb 2024)	2024-02-14 14:38:38
1422	A2CPS_Plate15	A2CPS Digested Peptides - Plate 15	2024-04-04 13:40:06
1423	A2CPS_Plate16	A2CPS Digested Peptides - Plate 16	2024-04-04 13:40:15
1424	A2CPS_Plate17	A2CPS Digested Peptides - Plate 17	2024-04-04 13:40:22
1425	A2CPS_Plate18	A2CPS Digested Peptides - Plate 18	2024-04-04 13:40:30
1426	A2CPS_Plate19	A2CPS Digested Peptides - Plate 19	2024-04-04 13:40:37
1427	A2CPS_Plate20	A2CPS Digested Peptides - Plate 20	2024-04-04 13:40:47
1428	UHICC_EA-AA_Plate-1	UHICC EA-AA Peptides from S-trap Digest Plate 1	2024-05-08 07:29:34
1429	UHICC_EA-AA_Plate-2	UHICC EA-AA Peptides from S-trap Digest Plate 2	2024-05-08 07:29:39
1430	UHICC_EA-AA_Plate-3	UHICC EA-AA Peptides from S-trap Digest Plate 3	2024-05-08 07:29:44
1431	Wistar_Peptides_Plate1	Wistar peptides from urea digest - Plate 1	2024-06-21 13:51:30
1432	Wistar_Peptides_Plate2	Wistar peptides from urea digest - Plate 2	2024-06-21 14:03:46
1433	Wistar_Peptides_Plate3	Wistar peptides from urea digest - Plate 3	2024-06-21 14:44:04
1434	Wistar_Peptides_Plate4	Wistar peptides from urea digest - Plate 4	2024-06-21 14:44:19
1435	Wistar_Peptides_Plate5	Wistar peptides from urea digest - Plate 5	2024-06-25 12:04:02
1436	Wistar_Peptides_Plate6	Wistar peptides from urea digest - Plate 6	2024-06-25 12:04:10
1437	Wistar_Peptides_Plate7	Wistar peptides from urea digest - Plate 7	2024-06-25 12:04:18
1438	A2CPS_Plate21	A2CPS Digested Peptides - Plate 21	2024-07-12 06:00:36
1439	A2CPS_Plate22	A2CPS Digested Peptides - Plate 22	2024-07-12 06:00:43
1440	A2CPS_Plate23	A2CPS Digested Peptides - Plate 23	2024-07-12 06:00:51
1441	A2CPS_Plate24	A2CPS Digested Peptides - Plate 24	2024-07-12 06:00:58
1442	A2CPS_Plate25	A2CPS Digested Peptides - Plate 25	2024-07-12 06:01:04
1443	A2CPS_Plate26	A2CPS Digested Peptides - Plate 26	2024-07-12 06:01:13
1444	A2CPS_Plate27	A2CPS Digested Peptides - Plate 27	2024-07-12 06:01:19
1445	HIV_Cohn_Plate_01	HIV_Cohn Depleted and Digested Peptides - Plate 1	2024-10-23 07:02:37.731113
1446	HIV_Cohn_Plate_02	HIV_Cohn Depleted and Digested Peptides - Plate 2	2024-10-23 07:02:43.704165
1447	HIV_Cohn_Plate_03	HIV_Cohn Depleted and Digested Peptides - Plate 3	2024-10-23 07:02:53.628135
1448	HIV_Cohn_Plate_04	HIV_Cohn Depleted and Digested Peptides - Plate 4	2024-10-23 07:02:58.408107
1449	HIV_Cohn_Plate_05	HIV_Cohn Depleted and Digested Peptides - Plate 5	2024-10-23 07:03:03.549242
1450	TEDDY_Val_2_Plate_01	TEDDY Validation 2 Digested Peptides - Plate 1	2024-11-13 13:42:56.483119
1451	TEDDY_Val_2_Plate_02	TEDDY Validation 2 Digested Peptides - Plate 2	2024-11-13 13:43:03.185216
1452	TEDDY_Val_2_Plate_03	TEDDY Validation 2 Digested Peptides - Plate 3	2024-11-20 12:03:35.098382
1453	TEDDY_Val_2_Plate_04	TEDDY Validation 2 Digested Peptides - Plate 4	2024-11-20 12:03:42.094915
1454	TEDDY_Val_2_Plate_05	TEDDY Validation 2 Digested Peptides - Plate 5	2024-11-25 08:46:22.561787
1455	TEDDY_Val_2_Plate_06	TEDDY Validation 2 Digested Peptides - Plate 6	2024-11-25 08:46:29.471781
1456	TEDDY_Val_2_Plate_07	TEDDY Validation 2 Digested Peptides - Plate 7	2024-12-02 11:17:40.251286
1457	TEDDY_Val_2_Plate_08	TEDDY Validation 2 Digested Peptides - Plate 8	2024-12-02 11:17:47.950612
1458	TEDDY_Val_2_Plate_09	TEDDY Validation 2 Digested Peptides - Plate 9	2024-12-02 11:36:57.89264
1459	TEDDY_Val_2_Plate_10	TEDDY Validation 2 Digested Peptides - Plate 10	2024-12-02 11:37:09.690564
\.


--
-- Name: t_wellplates_wellplate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_wellplates_wellplate_id_seq', 1459, true);


--
-- PostgreSQL database dump complete
--

