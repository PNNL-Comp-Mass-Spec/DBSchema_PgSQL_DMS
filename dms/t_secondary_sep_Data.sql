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
-- Data for Name: t_secondary_sep; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_secondary_sep (separation_type_id, separation_type, comment, active, separation_group, sample_type_id, created) FROM stdin;
139	Evosep_100_SPD_11min	Evosep	1	Evosep_100_SPD_11min	0	2024-04-22 16:32:59
140	Evosep_200_SPD_6min	Evosep	1	Evosep_200_SPD_6min	0	2024-04-22 16:32:59
137	Evosep_30_SPD_44min	Evosep	1	Evosep_30_SPD_44min	0	2024-04-22 16:32:59
141	Evosep_300_SPD_3min	Evosep	1	Evosep_300_SPD_3min	0	2024-04-22 16:32:59
138	Evosep_60_SPD_21min	Evosep	1	Evosep_60_SPD_21min	0	2024-04-22 16:32:59
136	Evosep_extended_15_SPD_88min	Evosep	1	Evosep_extended_15_SPD_88min	0	2024-04-22 16:32:59
28	LC-Agilent-2D-Formic	Online 2D separation using constant flow Agilent pumps	1	LC-2D-Formic	1	2010-06-17 12:07:50
78	LC-Agilent-2D-Intact	Agilent constant flow, intact proteins	1	LC-Agilent-2D-Intact	2	2014-02-10 15:53:26
25	LC-Agilent-Formic_100minute	Agilent constant flow, formic acid solvent, 100 minute separation	1	LC-Formic_100min	1	2010-01-08 12:33:28
30	LC-Agilent-Formic_120minute	Agilent constant flow, formic acid solvent, 120 minute separation	0	LC-Formic_100min	1	2010-01-05 15:40:47
27	LC-Agilent-Formic_15minute	Agilent constant flow, formic acid solvent, 15 minute separation	0	LC-Formic_30min	1	2010-07-20 10:49:16
116	LC-Agilent-Formic_2hr	Agilent constant flow, formic acid solvent, 2 hour separation	1	LC-Formic_2hr	1	2020-10-09 10:41:56
26	LC-Agilent-Formic_30minute	Agilent constant flow, formic acid solvent, 30 minute separation	1	LC-Formic_30min	1	2010-02-05 08:26:45
80	LC-Agilent-Formic_3hr	Agilent constant flow, formic acid solvent, 3 hour separation	1	LC-Formic_3hr	1	2014-04-24 10:29:57
73	LC-Agilent-Formic_45minute	Agilent constant flow, formic acid solvent, 45 minute separation	0	LC-Formic_45min	1	2012-09-01 14:39:20
81	LC-Agilent-Formic_5hr	Agilent constant flow, formic acid, 300 minute (5 hr) separation	0	LC-Formic_5hr	1	2014-04-10 17:50:58
29	LC-Agilent-Formic_60minute	Agilent constant flow, formic acid solvent, 60 minute separation	1	LC-Formic_1hr	1	2010-01-11 11:05:32
31	LC-Agilent-Metabolomics_LipidSoluble	Agilent constant flow, mobile phase optimized for lipid soluble metabolites	0	LC-Metabolomics_LipidSoluble	4	2010-06-29 14:40:36
58	LC-Agilent-Phospho	Phosphopeptide separations using an Agilent LC pump	0	LC-Phospho	1	2012-02-29 16:48:35
114	LC-Agilent-ZIC-HILIC_22min	Agilent high flow LC, optimized for water soluble metabolites	1	LC-HILIC	3	2019-07-08 15:50:46
65	LC-AMOLF-Standard	Datasets acquired at AMOLF	0	Other	0	2012-12-03 12:51:19
49	LC-Broad-Phospho	Datasets acquired at the Broad Institute	0	Other	0	2012-01-13 15:43:56
10	LC-Broad-Standard	Datasets acquired at the Broad Institute	0	Other	0	2006-10-09 16:22:17
50	LC-Bruker-Advance	Bruker Advance LC	0	Other	0	2012-01-31 12:15:48
121	LC-Dionex-Acetylome-2hr	Dionex LC, 2 hr separation	1	LC-Acetylome	1	2021-08-11 09:18:52
87	LC-Dionex-Formic_100min	Dionex LC, formic acid, 100 minute separation	1	LC-Formic_100min	1	2014-12-11 15:31:52
132	LC-Dionex-Formic_1hr	Dionex LC, formic acid, 1 hr separation	1	LC-Formic_1hr	1	2023-05-04 08:47:02
117	LC-Dionex-Formic_2hr	Dionex LC, formic acid, 2 hr separation	1	LC-Formic_2hr	1	2020-10-09 10:49:32
115	LC-Dionex-Formic_30min	Dionex LC, formic acid, 30 minute separation	1	LC-Formic_30min	1	2020-02-27 10:00:00
104	LC-Dionex-Formic_3hr	Dionex LC, formic acid, 180 minute (3 hr) separation	1	LC-Formic_3hr	1	2017-08-31 16:34:20
88	LC-Dionex-Formic_5hr	Dionex LC, formic acid, 300 minute (5 hr) separation	1	LC-Formic_5hr	1	2016-01-28 21:28:29
125	LC-Dionex-Formic_90min	Dionex, formic acid, 90 minute separation	1	LC-Formic_90min	1	2022-12-20 12:43:14
109	LC-Dionex-NanoPot_100min		1	LC-NanoPot_2hr	0	2018-09-02 08:12:29
110	LC-Dionex-NanoPot_150min		1	LC-NanoPot_3hr	0	2018-10-19 20:56:42
108	LC-Dionex-NanoPot_1hr		1	LC-NanoPot_1hr	0	2018-09-04 11:36:14
118	LC-Dionex-NanoPot_2hr		1	LC-Formic_2hr	1	2020-10-09 11:17:38
142	LC-Dionex-NH4OAc_40min	Dionex LC, ammonium acetate, 25 minute separation, 40 minute total	1	Other	3	2024-05-24 13:38:09
38	LC-Eksigent-Formic	Eksigent nanoflow, formic acid	0	LC-Eksigent	1	2010-09-17 16:26:59
66	LC-Eksigent-Formic_100min	Eksigent nanoflow, formic acid, 100 minute separation	0	LC-Eksigent	1	2012-01-17 08:49:39
46	LC-Eksigent-Formic_10hr	Eksigent nanoflow, formic acid, 600 minute (10 hr) separation	0	LC-Eksigent	1	2012-11-27 14:48:59
67	LC-Eksigent-Formic_3hr	Eksigent nanoflow, formic acid, 180 minute (3 hr) separation	0	LC-Eksigent	1	2010-10-03 17:14:58
69	LC-Eksigent-Formic_5hr	Eksigent nanoflow, formic acid, 300 minute (5 hr) separation	0	LC-Eksigent	1	2012-01-17 08:49:39
68	LC-Eksigent-Formic_60min	Eksigent nanoflow, formic acid, 60 minute separation	0	LC-Eksigent	1	2010-10-13 09:17:36
59	LC-Eksigent-Phospho	Phosphopeptide separations using an Eksigent LC pump	0	LC-Eksigent	1	2013-02-11 12:01:01
105	LC-Emory-Standard	Datasets acquired at the Emory School of Medicine	0	Other	0	2018-01-15 19:54:09
9	LC-FHCRC-Standard	Datasets acquired at FHCRC	0	Other	0	2005-11-17 16:54:11
106	LC-IMER-ND_2hr	IMER cart, but no digestion (bypass the IMER column); 2 hour separation	1	LC-IMER-ND_2hr	1	2018-05-15 19:54:09
107	LC-IMER-ND_3hr	IMER cart, but no digestion (bypass the IMER column); 3 hour separation	1	LC-IMER-ND_3hr	1	2018-05-15 19:54:09
84	LC-IMER_2hr	LC system with online trypsin digestion, 2 hour separation	0	LC-IMER_2hr	1	2015-05-18 15:37:43
85	LC-IMER_3hr	LC system with online trypsin digestion, 3 hour separation	1	LC-IMER_3hr	1	2015-06-08 10:04:33
86	LC-IMER_5hr	LC system with online trypsin digestion, 5 hour separation	0	LC-IMER_5hr	1	2015-06-09 14:15:17
18	LC-ISCO-Formic_100minute	ISCO system, formic acid solvent, 100 minute separation (exponential dilution gradient)	0	LC-Formic_100min	1	2007-11-07 23:13:01
12	LC-ISCO-Formic_15minute	ISCO system, formic acid solvent, 15 minute separation	0	Other	1	2007-03-06 08:23:16
11	LC-ISCO-Formic_35minute	ISCO system, formic acid solvent, 35 minute separation	0	LC-Formic_30min	0	2006-12-18 11:26:56
74	LC-ISCO-Formic_50minute	ISCO system, formic acid solvent, 50 minute separation (exponential dilution gradient)	0	LC-Formic_1hr	1	2013-02-14 13:25:17
20	LC-ISCO-Formic_80minute	ISCO system, formic acid solvent, 80 minute separation	0	LC-Formic_80min	1	2008-05-15 09:23:58
15	LC-ISCO-Metabolomics_LipidSoluble	ISCO system, mobile phase optimized for lipid soluble metabolites	0	LC-Metabolomics_LipidSoluble	4	2007-01-23 14:33:45
14	LC-ISCO-Metabolomics_WaterSoluble	ISCO system, mobile phase optimized for water soluble metabolites	0	LC-Metabolomics_WaterSoluble	3	2006-05-04 11:32:23
19	LC-ISCO-Phospho	General setting for Isco Phospho cart work	0	LC-Phospho	1	2008-04-11 14:33:26
4	LC-ISCO-Special	ISCO system, special mobile phase and/or long gradients	0	Other	1	2000-05-15 13:13:57
2	LC-ISCO-Standard	ISCO system, standard solvents (TFA), 100 to 180 minute separation (exponential dilution gradient)	0	LC-TFA_100minute	1	2000-05-15 13:13:57
13	LC-ISCO-Standard_15minute	ISCO system, standard solvents (TFA), 15 minute separation	0	Other	1	2007-05-03 08:40:17
16	LC-ISCO-Standard_35minute	ISCO system, standard solvents (TFA), 35 minute separation (50 or 75 um column)	0	Other	1	2006-04-05 07:59:47
17	LC-ISCO-Standard_50minute	ISCO system, standard solvents (TFA), 50 minute separation (150 um column)	0	Other	0	2012-10-17 11:12:28
77	LC-JCVI-Standard	Datasets acquired at JCVI	0	Other	0	2014-01-20 18:27:53
62	LC-JHU-Standard	Datasets acquired at Johns Hopkins University	0	Other	0	2012-06-05 21:52:40
21	LC-KoreaU-Standard	Datasets acquired at Korea University	0	Other	0	2009-07-28 18:58:49
63	LC-MIT-Standard	Datasets acquired at Forest White's lab at MIT	0	Other	0	2012-06-05 21:52:46
143	LC-Neo-Formic_10Min	Neo, formic acid, 10 min separation	1	LC-Formic_10Min	1	2024-05-30 10:29:32
127	LC-Neo-Formic_1hr	Neo, formic acid, 1 hour separation	1	LC-Formic_1hr	1	2022-12-20 12:46:10
144	LC-Neo-Formic_20Min	Neo, formic acid, 20 Min separation	1	LC-Formic_20Min	1	2024-05-30 10:30:01
128	LC-Neo-Formic_2hr	Neo, formic acid, 2 hour separation	1	LC-Formic_2hr	1	2022-12-20 12:46:28
145	LC-Neo-Formic_30min	Neo LC, formic acid, 30 minute separation	1	LC-Formic_30min	1	2024-05-30 10:33:58
129	LC-Neo-Formic_3hr	Neo, formic acid, 3 hour separation	1	LC-Formic_3hr	1	2022-12-20 12:46:45
126	LC-Neo-Formic_90min	Neo, formic acid, 90 minute separation	1	LC-Formic_90min	1	2022-12-20 12:45:52
94	LC-NU-Standard	Datasets acquired in the Kelleher lab at Northwestern	0	Other	0	2015-11-05 11:10:50
7	LC-ORNL-Standard	Datasets acquired at Oak Ridge National Lab	0	Other	0	2004-09-27 16:26:09
124	LC-PCR-Tube_2hr	LC-PCR-Tube_2hr	1	LC-PCR-Tube	1	2022-11-15 08:29:27
102	LC-Pentylammonium_highflow_High_pH	Waters constant high flow, ion pairing pentylamine plus HFIP, high pH	1	LC-IonPairing	0	2017-10-09 15:40:24
32	LC-PFGRC-Standard	Datasets acquired in the Pathogen Functional Genomics Resource Center at JCVI	0	Other	0	2010-08-16 18:21:54
101	LC-ReproSil-75um	75 um columns packed with 1.9 um Reprosil porous particles	1	LC-ReproSil-75um	1	2016-11-23 10:45:35
133	LC-Rush-Standard	Datasets acquired at Rush University	0	Other	0	2023-08-23 13:07:28
79	LC-UNC-Standard	Datasets acquired at the University of North Carolina	0	Other	0	2014-03-07 15:54:39
55	LC-Unknown	Unknown LC separation	0	Other	0	2010-09-13 13:38:29
53	LC-Vanderbilt-Standard	Datasets acquired at Vanderbilt University	0	Other	0	2012-03-20 21:48:13
96	LC-Vanquish-AA	Vanquish high flow LC, optimized for amino acid separation	1	LC-HiFlow	0	2015-11-15 11:10:50
89	LC-Vanquish-Formic_100min	Vanquish high flow LC, formic acid, 100 minute separation	1	LC-HiFlow	1	2014-08-28 16:56:48
90	LC-Vanquish-Formic_300min	Vanquish high flow LC, formic acid, 300 minute (5 hr) separation	1	LC-HiFlow	0	2016-08-17 15:03:32
92	LC-Vanquish-Formic_30min	Vanquish high flow LC, formic acid, 30 minute separation	1	LC-HiFlow	1	2015-03-24 14:42:23
91	LC-Vanquish-Formic_60min	Vanquish high flow LC, formic acid, 60 minute separation	1	LC-HiFlow	0	2015-01-29 17:41:35
93	LC-Vanquish-HILIC	Vanquish high flow LC, HILIC	1	LC-HiFlow	0	2015-08-06 16:26:53
98	LC-Vanquish-Lipids_35min	Vanquish high flow LC, optimized for lipid separation	1	LC-HiFlow	4	2016-08-17 13:48:43
103	LC-Vanquish_Pentylammonium_highflow_High_pH	Vanquish constant high flow, ion pairing pentylamine plus HFIP, high pH	1	LC-IonPairing	0	2017-02-24 16:34:20
61	LC-WashU-Standard	CPTAC datasets acquired at Washington University in St. Louis	0	Other	0	2012-05-14 20:44:55
33	LC-Waters-2D-Formic	Waters constant flow, formic acid 2D-LC	1	LC-2D-Formic	1	2011-02-19 12:12:00
120	LC-Waters-Acetylome-2hr	Waters LC, 2 hr separation	1	LC-Acetylome	1	2021-08-11 07:48:34
37	LC-Waters-Formic_100min	Waters constant flow, formic acid, 100 minute separation	0	LC-Formic_2hr	1	2010-08-26 12:24:53
45	LC-Waters-Formic_10hr	Waters constant flow, formic acid, 600 minute (10 hr) separation	0	Other	1	2011-11-10 07:38:11
130	LC-Waters-Formic_150min	Waters constant flow, formic acid, 150 minute separation	1	LC-Formic_150min	1	2023-01-31 16:11:11
34	LC-Waters-Formic_20min	Waters constant flow, formic acid, 20 minute separation	0	LC-Formic_30min	0	2010-09-07 22:08:49
100	LC-Waters-Formic_2hr	Waters constant flow, formic acid, 120 minute (2 hr) separation	1	LC-Formic_2hr	1	2017-02-01 20:33:12
35	LC-Waters-Formic_30min	Waters constant flow, formic acid, 30 minute separation	1	LC-Formic_30min	0	2010-08-28 13:03:43
47	LC-Waters-Formic_3hr	Waters constant flow, formic acid, 180 minute (3 hr) separation	1	LC-Formic_3hr	1	2010-09-12 14:04:19
6	CE	Capillary electrophoresis	1	CE	0	2001-01-24 15:50:06
5	CIEF	Capillary electrophoresis	0	CE	0	2001-01-24 15:43:06
134	Evosep_Whisper_20_SPD_60min	Evosep	1	Evosep_Whisper_20_SPD_60min	0	2023-09-12 14:07:31
135	Evosep_Whisper_40_SPD_30min	Evosep	1	Evosep_Whisper_40_SPD_30min	0	2023-09-12 14:07:41
52	GC-Agilent-FAMEs	Fatty acid methyl ethers generated by acid or base hydrolysis with methanol, DB-5MS	1	GC	3	2012-06-18 17:27:23
22	GC-Agilent-Fiehn	Global metabolomics analysis after chemical derivatizations	1	GC	3	2010-07-30 10:19:39
23	GC-Agilent-Special	Agilent GC special	1	GC	3	2011-03-25 14:03:15
51	GC-Agilent-Volatile	Volatile small metabolite with DB-FFAP or similar	1	GC	3	2012-06-18 17:26:02
113	GC-Shimadzu		1	GC	0	2019-05-08 15:50:46
97	GC-Thermo	Thermo QExactive with built-in GC	1	GC	0	2015-11-30 14:44:05
44	Glycans	General linear gradient for glycan analysis using formic acid based mobile phases	1	Glycans	5	2012-08-17 16:59:49
82	Infusion	Direct infusion	1	Infusion	0	2013-04-09 11:46:21
72	LC-2D-Custom		0	LC-2D-Custom	0	2014-10-07 13:44:40
75	LC-ABRF-Standard	Datasets associated with ABRF studies	0	Other	0	2013-11-26 17:15:57
3	LC-Agilent	Non-specific Agilent LC; Please avoid using this type for new datasets	0	LC-Formic_100min	0	2000-05-15 13:13:57
8	LC-Agilent-Special	Non-standard Agilent LC	1	Other	1	2005-01-28 15:19:02
70	LC-Eksigent-Formic_High-pH	Eksigent nanoflow, high pH	0	LC-Eksigent	0	2012-01-17 08:49:39
39	LC-Waters-Formic_40min	Waters constant flow, formic acid, 40 minute separation	1	LC-Formic_1hr	1	2010-10-04 10:22:04
48	LC-Waters-Formic_4hr	Waters constant flow, formic acid, 240 minute (4 hr) separation	1	LC-Formic_4hr	1	2012-01-17 11:06:41
36	LC-Waters-Formic_52min	Waters constant flow, formic acid, 52 minute separation	0	LC-Formic_1hr	0	2010-08-23 11:24:50
56	LC-Waters-Formic_5hr	Waters constant flow, formic acid, 300 minute (5 hr) separation	1	LC-Formic_5hr	1	2012-04-25 10:36:56
40	LC-Waters-Formic_60min	Waters constant flow, formic acid, 60 minute separation	1	LC-Formic_1hr	1	2010-10-07 13:46:25
119	LC-Waters-Formic_90min	Waters constant flow, formic acid, 90 minute separation	1	LC-Formic_90min	1	2020-10-09 11:18:56
95	LC-Waters-GlcNAc	GlcNAc separations using a Waters LC pump	1	LC-GlcNAc	0	2015-11-15 11:10:50
99	LC-Waters-HC-Lipids_35min	Waters constant flow,optimized for lipids, 35 minute separation	1	LC-Metabolomics_LipidSoluble	4	2016-08-30 09:26:58
41	LC-Waters-IntactProtein_200min	Waters constant flow, 200 minute separation, high molecular weight analytes	1	LC-IntactProtein_200min	2	2010-11-30 09:25:31
131	LC-Waters-Metabolomics-LipidSoluble	Waters system, mobile phase optimized for lipid soluble metabolites. Samples in 2:1 chloroform:methanol before drying down and analyzing, in 9:1 methanol:chloroform after drying down	1	LC-Metabolomics_LipidSoluble	4	2023-04-26 14:38:13
43	LC-Waters-Metabolomics_LipidSoluble	Waters system, mobile phase optimized for lipid soluble metabolites	1	LC-Metabolomics_LipidSoluble	4	2011-01-12 11:16:13
123	LC-Waters-Metabolomics_LipidSoluble_25MinGradient	Waters system, mobile phase optimized for lipid soluble metabolites	1	LC-Metabolomics_LipidSoluble	4	2022-10-24 20:26:29
122	LC-Waters-Metabolomics_Sonnenburg	Waters system, gradient optimized for mammalian polar metabolites	1	LC-Metabolomics_Sonnenburg	4	2022-02-16 11:09:19
42	LC-Waters-Metabolomics_WaterSoluble	Waters system, mobile phase optimized for water soluble metabolites	1	LC-Metabolomics_WaterSoluble	3	2013-01-21 08:58:06
71	LC-Waters-NH4HCO2_100min	Waters constant flow, 10 mM ammonium bicarbonate, 100 minute separation	1	LC-Waters-NH4HCO2	0	2016-06-15 14:32:59
112	LC-Waters-Oxylipids_30min		1	LC-Metabolomics_Oxylipids	0	2019-11-14 08:23:43
60	LC-Waters-Phospho	Phosphopeptide separations using a Waters LC pump	1	LC-Phospho	1	2012-06-13 11:35:17
54	LC-Waters-PRISM	Generic separation for fractionation	1	LC-PRISM	0	2012-03-22 15:10:57
57	LC-Waters_High_pH	Waters constant flow, high pH	1	LC-Waters_High_pH	1	2012-04-26 12:20:20
76	LC-Waters_Neutral_pH_100min	Waters constant flow, neutral pH	1	LC-Waters_Neutral	1	2013-12-10 07:16:12
1	none	Direct infusion (no LC)	1	Other	0	2000-05-15 10:36:14
64	Prep_HPLC	Prep HPLC separation; see associated Prep_LC_Run entry for column details	1	Other	0	2012-09-21 15:20:20
111	RapidFire-SPE	RapidFire device	1	RapidFire-SPE	0	2018-09-14 20:03:24
24	RPLC_HILIC	Online 2D separation using RPLC then HILIC	0	LC-2D-HILIC	0	2010-01-01 10:12:29
\.


--
-- PostgreSQL database dump complete
--

