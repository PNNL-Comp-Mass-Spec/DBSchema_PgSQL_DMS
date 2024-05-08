--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
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
-- Data for Name: t_mass_correction_factors; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_mass_correction_factors (mass_correction_id, mass_correction_tag, description, monoisotopic_mass, average_mass, affected_atom, original_source, original_source_name, alternative_name, empirical_formula) FROM stdin;
1120	Acetyl	Acetylation	42.010567	42.0367	-	UniMod	Acetyl	Acetylation	C(2) H(2) O
1529	AcNoTMT16	Acetylation on TMT16-labeled samples; for use when using a static TMT 16-plex mod	-262.196586	\N	-	PNNL	AcetNoTMT16	\N	\N
1530	CbNoTMT16	Carbamylation on TMT-labled samples; for use when using a static TMT 6-plex mod	-261.201332	\N	-	PNNL	CarbamylNoTMT16	\N	\N
1535	MethNoTMT	Methylation on TMT-labeled samples; remove 6-plex TMT and add Methyl	-215.147283	\N	-	PNNL	MethylNoTMT	\N	H(-18) C(-7) 13C(-4) N(-1) 15N(-1) O(-2)
1536	UbNoTMT16	Ubiquitination on TMT-labeled samples; remove 16-plex TMT and add Ubiq	-190.164215	\N	-	PNNL	UbiqNoTMT16	\N	\N
1495	AcNoTMT	Acetylation on TMT-labeled samples; remove 6-plexe TMT and add Acetyl	-187.15234	\N	-	PNNL	AcetNoTMT	\N	H(-18) C(-6) 13C(-4) N(-1) 15N(-1) O(-1)
1521	Me3NoTMT	Trimethylation on TMT-labeled samples; remove 6-plex TMT and add tri-methylation	-187.115983	\N	-	PNNL	TrimethylNoTMT	\N	\N
1518	TriMethNoTMT	Dupe/Obsolete; use ME3NoTMT	-187.1158	\N	-	PNNL	TriMethylNoTMT	\N	\N
1520	Me3MockNoTMT	Mock trimethyl K residues that do not have TMT	-187.07995	\N	-	PNNL	Me3MockNoTMT	\N	\N
1507	CbNoTMT	Carbamylation on TMT-labled samples; remove 6-plex TMT and add Carbamyl	-186.157086	\N	-	PNNL	CarbamylNoTMT	\N	\N
1499	AcNoTMT0	Acetylation on TMT-zero labeled samples; remove TMT zero and add Acetylation	-182.141911	\N	-	PNNL	AcetNoTMT0	\N	H(-18) C(-10) N(-2) O(-2)
1525	CbNoTMT0	Carbamylation on TMT-zero labeled samples	-181.146664	\N	-	PNNL	CarbamylNoTMT0	\N	\N
1378	Met_Loss	Removal of initiator methionine from protein N-terminus	-131.040482	\N	-	UniMod	Met-loss	\N	H(-9) C(-5) N(-1) O(-1) S(-1)
1511	SucNoTMT	Succinylation on TMT-labeled samples; remove 6-plex TMT and add Succinyl	-129.146888	\N	-	PNNL	SuccylNoTMT	\N	H(-16) C(-4) 13C(-4) N(-1) 15N(-1) O(1)
1468	LysLoss	Loss of Lysine (typically from the Protein C-terminus)	-128.0949582	\N	-	UniMod	Lys-loss	\N	C(-6) H(-12) N(-2) O(-1)
1534	UbNoTMT	Ubiquitination on TMT-labeled samples; remove 6-plex TMT and add Ubiq	-115.12	\N	-	PNNL	UbiqNoTMT	\N	\N
1544	UbNoTMT0	Ubiquitination on TMT-labeled samples; remove TMT zero and add Ubiq	-110.109547	\N	-	PNNL	UbiqNoTMT0	\N	\N
1379	MetLossA	Removal of initiator methionine from protein N-terminus, then acetylation of the new N-terminus	-89.029922	\N	-	UniMod	Met-loss+Acetyl	\N	H(-7) C(-3) N(-1) S(-1)
1161	HMOSERLC	Homoserine Lactone from Methionine	-48.003372	-48.1075	-	UniMod	Dethiomethyl	Homoserine Lacton	H(-4) C(-1) S(-1)
1475	Se80ToS	Sec changed to Cysteine, Se80 variant	-47.9445	\N	-	PNNL		\N	S(1) Se(-1)
1473	Se78ToS	Sec changed to Cysteine, Se78 variant	-45.9452	\N	-	PNNL		\N	\N
1172	GamGluAl	Arginine oxidation to gamma-glutamyl semialdehyde	-43.053432	-43.0711	-	UniMod	Arg->GluSA	GamGluAl	H(-5) C(-1) N(-3) O
1198	Sulf-10	AlkSulf, shifted -10 Da	-35.0316	-35.0525	-	PNNL		Sulfinic cys oxidation, -10 Da	\N
1340	Cys-Dha	Dehydroalanine (from Cysteine	-33.98772	-34.0809	-	UniMod	Cys->Dha	DehydroalaC	H(-2) S(-1)
1406	LysToVal	Lysine to Valine substitution	-29.026549	\N	-	UniMod	Lys->Val	\N	H(-3) C(-1) N(-1)
1498	ArgToLys	Arg to Lys substitution	-28.006148	-28.0134	-	UniMod	Arg->Lys	\N	N(-2)
1178	AlkSulf	Minus C2H3NO and Plus O2 -> Minus C2H3N and Plus O	-25.0316	-25.0525	-	PNNL		Sulfinic cys oxidation	C(-2) H(-3) N(-1) O
1234	HisOxyN	Rearrangement and addition of oxygen to obtain Asparagine	-23.015984	-23.0366	-	UniMod	His->Asn	His2Asn	H(-1) C(-2) N(-1) O
1235	HisOxyD	Rearrangement and addition of oxygen to obtain Aspartic Acid	-22.031969	-22.0519	-	UniMod	His->Asp	His2Asp	H(-2) C(-2) N(-2) O(2)
1463	MetToHBG	Substitution of HBG for Met during translation	-21.98772	-22.07118	-	PNNL	MetToHBG	\N	C(1) H(-2) S(-1)
1199	Sulf2-10	AlkSulf2, shifted -10 Da	-19.0367	-19.0532	-	PNNL		Sulfonic cys oxidation, -10 Da	\N
1121	MinusH2O	Water loss (dehydration)	-18.010565	-18.0153	-	UniMod	Dehydrated	Water loss	H(-2) O(-1)
1339	OxoAla	Oxoalanine	-17.992805	-18.0815	-	UniMod	Cys->Oxoalanine	Oxoalanine	H(-2) O1 S(-1)
1169	NH3_Loss	Ammonia loss (e.g. Pyro-Glu from Q)	-17.026548	-17.0305	-	UniMod	Gln->pyro-Glu	NH3_Loss	H(-3) N(-1)
1270	Pro2Azet	amino acid substitution of Proline to Azetidine-2-carbolylate	-14.01565	\N	-	UniMod	Ala->Gly	\N	H(-2) C(-1)
1166	ROBLOSS	Differential Succ. Anhyd. to NHS-SS-Biotin	-11.876	\N	-	PNNL		ROBLOSS	\N
1388	AsnToCys	Asn to Cys substitution	-11.033743	\N	-	UniMod	Asn->Cys	Misacylation of the tRNA or editing of the charged tRNA	H(-1) C(-1) N(-1) O(-1) S
1271	Nonesens	A physically impossible mod mass to test for false PTM discovery	-11	\N	-	PNNL		\N	\N
1197	AlkSulf2	Minus C2H3NO and Plus O3 -> Minus C2H3N and Plus O2	-9.0367	-9.0532	-	PNNL		Sulfonic cys oxidation	C(-2) H(-3) N(-1) O2
1389	HisToGlu	His to Glu substitution	-8.016319	\N	-	UniMod	His->Glu	Misacylation of the tRNA or editing of the charged tRNA	C(-1) N(-2) O(2)
1393	TyrToArg	Tyr to Arg substitution	-6.962218	\N	-	UniMod	Tyr->Arg	Misacylation of the tRNA or editing of the charged tRNA	H(3) C(-3) N(3) O(-1)
1391	ThrToPro	Thr to Pro substitution	-3.994915	\N	-	UniMod	Thr->Pro	Misacylation of the tRNA or editing of the charged tRNA	C O(-1)
1392	MetToLys	Met to Lys substitution	-2.945522	\N	-	UniMod	Met->Lys	Misacylation of the tRNA or editing of the charged tRNA	H(-1) N O S(-1)
1173	AmOxButa	Threonine oxidation to 2-amino-3-oxo-butanoic acid	-2.01565	-2.0159	-	UniMod	Didehydro	AmOxButa	H(-2)
1174	AmAdipic	Lysine oxidation to aminoadipic semialdehyde	-1.031634	-1.0311	-	UniMod	Lys->Allysine	AmAdipic	H(-3) N(-1) O
1272	Dehydro	Loss of hydrogen atom	-1.007825	\N	-	UniMod	Dehydro	\N	H(-1)
1361	C12-C13	Difference in mass between carbon-12 and carbon-13	-1.003355	\N	-	PNNL		\N	13C(-1)
1298	BetaElim	Beta elimination from Serine or Threonine	-0.9848	\N	-	PNNL		\N	\N
1243	CTrmAmid	Amidation of the peptide C-Terminus, wherein the OH is replaced	-0.984016	\N	-	UniMod	Amidated	\N	H N O(-1)
1	None	no modification	0	0	-	PNNL		None	
1127	Deamide	Deamidation	0.984016	0.9848	-	UniMod	Deamidated	Deamidation	H(-1) N(-1) O
1007	Iso_N15	Isotopic N15	0.997035	0.9934	N	UniMod	Label:15N(1)	Iso_N15	N(-1) 15N
1162	Iso_C13	Isotopic C13	1.00335	0.9927	C	PNNL		Iso_C13	C(-1) 13C
1154	DiffDeut	Differential Deuteration	1.0063	\N	-	PNNL		DiffDeut	\N
1519	DeamideMock	Mock Deamidation: 0.0193 + 1.0034; to estimate the FDR of the deamidation and citrullination peptides	1.022694	\N	-	PNNL	MockDeamidated	\N	\N
1322	N15_2x	Residue with two 15N-labeled atoms	1.99407	1.9868	K	UniMod	Label:15N(2)	N15_2x	N(-2) 15N(2)
1390	GluToMet	Glu to Met substitution	1.997892	\N	-	UniMod	Glu->Met	Misacylation of the tRNA or editing of the charged tRNA	H(2) O(-2) S
1334	NEProbe	ABP NE Probe for lysine	95.0491	\N	-	PNNL		\N	\N
1149	One_O18	One O18 addition	2.004246	1.9998	-	UniMod	Label:18O(1)	One_O18	O(-1) 18O
1062	Iso_O18	Isotopic O18	2.004246	1.9998	O	UniMod	Label:18O(1)	Iso_O18	O(-1) 18O
1303	2xDeut	Incorporation of 2 deuterium atoms for SILAC	2.0126	\N	-	PNNL		\N	\N
1405	LysToMet	Lysine to Methionine substitution	2.945522	\N	-	UniMod	Lys->Met	\N	H(-3) C(-1) N(-1) S
1295	O18Dcsyl	Deamidation of glycosylated Asparagine (N) in the presence of	2.988261	\N	-	UniMod	Deamidated:18O(1)	\N	H(-1) N(-1) 18O
1323	N15_3x	Residue with three 15N-labeled atoms	2.991105	2.9802	H	UniMod	Label:15N(3)	N15_3x	N(-3) 15N(3)
1343	2C131N15	incorporation of 2 x 13C and 1 x 15N Gly	3.00374434	2.97867	-	PNNL	Label:13C(2)15N(1)	\N	\N
1325	N15_4x	Residue with four 15N-labeled atoms	3.98814	3.9736	R	UniMod	Label:15N(4)	N15_4x	N(-4) 15N(4)
1233	TrypOxy	Rearrangement and oxidation of tryptophan	3.994915	3.9887	-	UniMod	Trp->Kynurenin	Pro2Thr	C(-1) O
1344	3C131N15	incorporation of 3 x 13C and 1 x 15N Ala Ser Cys	4.007099	3.9714	-	UniMod	Label:13C(3)15N(1)	\N	C(-3) 13C(3) N(-1) 15N
1150	Two_O18	Two O18 addition	4.008491	3.9995	-	UniMod	Label:18O(2)	Two O18	O(-2) 18O(2)
1214	4xDeut	Incorporation of 4 deuterium atoms into Lysine for SILAC	4.025107	\N	-	UniMod	Label:2H(4)	\N	H(-4) 2H(4)
1350	4C131N15	incorporation of 4 x 13C and 1 x 15N Asp Thr	5.010454	4.964	-	UniMod	Label:13C(4)15N(1)	\N	C(-4) 13C(4) N(-1) 15N
1302	5C13	Five Carbon 13	5.016774	4.9633	-	UniMod	Label:13C(5)	13C5	C(-5) 13C(5)
1336	Phe-D5	5 deuterium on Phenylalanine, C9H6D5NO2	5.0309	\N	-	PNNL		\N	\N
1352	4C135N15	incorporation of 5 x C13 and 2 x N15 Asn	5.95577	5.95577	-	PNNL		\N	\N
1355	4C132N15	incorporation of 4 x 13C and 2 x 15N Asn	6.00748868	5.95734	-	PNNL	Label:13C(2)15N(2)	\N	\N
1470	3O18	Three Oxygen 18	6.01275	\N	-	PNNL	Label:18O(3)	Three O18	O(-3) 18O(3)
1351	5C131N15	incorporation of 5 x 13C and 1 x N15 Glu Pro Met Val	6.013809	5.9567	-	UniMod	Label:13C(5)15N(1)	\N	C(-5) 13C(5) N(-1) 15N
1186	6C13	Six Carbon 13	6.020129	5.9559	-	UniMod	Label:13C(6)	13C6	C(-6) 13C(6)
1359	5C132N15	incorporation of 5 x 13C and 2 x 15N Gln	7.01084335	6.97945	-	PNNL	Label:13C(5)15N(2)	\N	\N
1157	6xC13N15	Six Carbon 13, 1 Nitrogen 15	7.017164	6.9493	-	UniMod	Label:13C(6)15N(1)	6xC13N15	C(-6) 13C(6) N(-1) 15N
1164	HeavyK	Six Carbon 13, 2 Nitrogen 15 (Heavy Lys)	8.014199	7.9427	-	UniMod	Label:13C(6)15N(2)	6C132N15	C(-6) 13C(6) N(-2) 15N(2)
1356	6C133N15	incorporation of 6 x 13C and 3 x 15N His	9.01123302	8.93601	-	PNNL	Label:13C(6)15N(3)	\N	\N
1165	HeavyR	Six Carbon 13, 4 Nitrogen 15 (Heavy Arg)	10.008269	9.9296	-	UniMod	Label:13C(6)15N(4)	6C134N15	C(-6) 13C(6) N(-4) 15N(4)
1163	9xC13N15	Nine Carbon 13, 1 Nitrogen 15	10.027228	9.9273	-	UniMod	Label:13C(9)15N(1)	9xC13N15	C(-9) 13C(9) N(-1) 15N
1335	D10-Leu	10 deuteriums on Leucine, C6H3D10NO2	10.062767	\N	-	UniMod	Label:2H(10)	\N	H(-10) 2H(10)
1182	One_C12	One Carbon 12 addition (crosslinking)	12	12.0107	-	UniMod	Thiazolidine	One_C12	C
1299	STMethyl	methylation of Ser ot Thr, -OH to -NH-CH3	13.0148	\N	-	PNNL		\N	\N
1357	11C32N15	incorporation of 11 x 13C and 2 x 15N Trp	13.03097137	12.90589	-	PNNL	Label:13C(11)15N(2)	\N	\N
1387	Methylmn	Methylamine	13.031634	\N	-	UniMod	Methylamine	Michael addition with methylamine	H(3) C N O(-1)
1213	OMinus2H	Oxygen addition, minus 2H; used for both Pyroglutamic and oxolactone	13.979265	13.9835	-	UniMod	Pro->pyro-Glu	Pyroglutamic	H(-2) O
1032	Methyl	Methylation	14.01565	14.0266	-	UniMod	Methyl	Methylation	H(2) C
1187	Deamethy	Deamidation of N or Q followed by methylation	14.96328	14.9683	-	PNNL		Aminoadipc	H C N(-1) O
1170	Aminaton	Addition of NH	15.010899	15.0146	-	UniMod	Amino	Amination (aka NH, appropriate for reaction with NH2)	H N
1115	Plus1Oxy	One O16 Addition (Oxidation)	15.994915	15.9994	-	UniMod	Oxidation	Oxidation	O
1194	NH2	NH2 addition	16.01872	16.0226	-	PNNL		NH2 (appropriate for reaction with NH3)	H(2) N
1158	Met_O18	Methylation with one O18	16.019896	16.0264	-	PNNL	Methyl:18O(1)		H(2) C O(-1) 18O
1570	Met_De	Deuterium methylation	16.028205	16.0389	-	UniMod	Methyl:2H(2)	DeMet	2H(2) C
1084	DeutMeth	Deuterated Methoxy	17.034479	17.045099	-	UniMod	Methyl:2H(3)	Deuterated Methoxy	H(-1) 2H(3) C
1221	LeuToMet	Replacement of Leuceine to Methionine alternate start site	17.956421	\N	-	UniMod	Xle->Met	\N	H(-2) C(-1) S
1159	Met_2O18	Methylation with Two O18	18.0241	18.0262	-	PNNL	Methyl_plus_two_O18	Methylation, two O18	H(2) C O(-2) 18O(2)
1569	Met_C13	Deuterium methylation with C13	18.037835	18.0377	-	UniMod	Methyl:2H(3)13C(1)	Methyl-Heavy	H(-1) 2H(3) 13C
1156	DuMtO18	One O18 & Deuterated Methoxy	19.0387	\N	-	PNNL		DuMtO18	H(-1) 2H(3) C O(-1) 18O
1209	NH+5Da	NH addition, plus 5 Da shift	20.0109	20.0147	-	PNNL		NH with 5 Da shift	\N
1183	Two_C12	Two Carbon 12 additions (crosslinking)	24	24.0214	-	PNNL	Delta:C(2)	Two_C12	C(2)
1337	Cyano	Cyano	24.995249	25.0095	-	UniMod	Cyano	Cyano	H(-1) C1 N1
1211	NH+10Da	NH addition, plus 10 Da shift	25.0109	25.0147	-	PNNL		NH with 10 Da shift	\N
1195	NH2+10Da	NH2 addition, plus 10 Da shift	26.01872	26.0226	-	PNNL		NH2 with 10 Da shift	\N
1276	Formam	Formamidination (+C1N1H1) of primary amines	27.010899	\N	-	UniMod	Ser->Asn	\N	H C N
1296	DiMetXOH	dimethylation replacing a hydroxyl (-OH)	27.0684	\N	-	PNNL		\N	\N
1155	Formyl	Formylation	27.994915	28.0101	-	UniMod	Formyl	Formylation	C O
1208	Dimethyl	Incorporation of two methyl moieties on the same amino acid	28.0313	28.0532	-	UniMod	Dimethyl	\N	H(4) C(2)
1566	Ethyl	Ethylation	28.0313000001	28.0532	-	UniMod	Ethyl	Ethyl	H(4) C(2)
1060	Nitrosyl	Nitrosylation	28.990164	28.9982	-	UniMod	Nitrosyl	Nitrosylation	H(-1) N O
1212	NH+15Da	NH addition, plus 15 Da shift	30.0109	30.0147	-	PNNL		NH with 15 Da shift	\N
1567	Ethyl_C13	Ethylation, heavy form	30.038009	30.0607	-	PNNL	Ethyl:13C(2)	\N	H(4) 13C(2)
1220	ValToMet	Switches Valine to Methionine for alternate start sites	31.972071	32.065	-	UniMod	Sulfide	persulfide	S
1064	Plus2Oxy	Two O16 Additions	31.989828	31.9988	-	UniMod	Dioxidation	Two O16	O(2)
1373	DeutForm	Addition of CHD2 (DiMethyl-CHD2)	32.056407	32.0778	-	UniMod	Dimethyl:2H(4)	CHD2	2H(4) C(2)
1420	Leu2MetO	Leu->Met, oxidized	33.951335	\N	-	UniMod	Leu->MetOx	\N	H(-2) C(-1) O S
1181	Chloro	Chlorination	33.96103	34.4448	-	PNNL		Chloro	H(-1) Cl
1218	Sulfur	Addition of sulfur atom	36.066	\N	-	PNNL		\N	\N
1375	C13DtFrm	Addition of 13CHD2 (13C and deuterium on formylation); also, heavy dimethylation	36.07567	36.0754	-	UniMod	Dimethyl:2H(6)13C(2)	Dimethyl-Heavy	H(-2) 2H(6) 13C(2)
1266	CAANL	Neutral loss of ammonia from chloroacetamidine (CAA)	39.010899	39.035999	-	UniMod	Phe->Trp	Ammonia_NL_from_Chloroacetamidine	H C(2) N
1338	Pyro-cmC	Pyro-cmC	39.994915	40.0208	-	UniMod	Pyro-carbamidomethyl	Glyoxal-derived hydroimiadazolone	C(2) O
1236	AcetAmid	Acetamidation, conversion of amine to acetamidine (by methyl acetimidate)	41.026549	\N	-	UniMod	Amidine	Amidine	H(3) C(2) N
1050	Guanid	Guanidination	42.021797	42.04	-	UniMod	Guanidinyl	Guanid	H(2) C N(2)
1083	DCAT_D0	DCAT d0	42.0375	0	-	PNNL		DCAT_D0	\N
1188	TriMeth	Triple methylation	42.046951	42.0797	-	UniMod	Trimethyl	Triple Methylation	H(6) C(3)
1384	EDA	Asn->Arg via ethylenediamine	42.058186	42.08312	-	UniMod	Asn->Arg	Ethylenediamine	H(6) C(2) N(2) O(-1)
1037	Carbamyl	Carbamyl Addition	43.005814	43.0247	-	UniMod	Carbamyl	Carbamyl	H C N O
1360	13CAcet	Acetylation with one C13	43.013919	\N	-	PNNL		\N	\N
1417	Carboxy	Carboxylation	43.989829	\N	-	UniMod	Carboxy	carboxyl	C O(2)
1049	EtShD0	EtSHd0	44.008457	44.118801	-	UniMod	Delta:H(4)C(2)O(-1)S(1)	EtShD0	H(4) C(2) O(-1) S
1036	NO2_Addn	NO2 Addition (Nitration)	44.985077	44.9976	-	UniMod	Nitro	Nitration	H(-1) N O2
1043	DCAT_D3	DCAT d3	44.9957	0	-	PNNL		DCAT_D3	\N
1472	SToSe78	Cys changed to Sec with Se78	45.9452	\N	-	PNNL		\N	\N
1416	Leu2MetF	Leu->Met, then formylation	45.951338	\N	-	PNNL		\N	H(-2) O S
1252	Meththio	Methylthio	45.98772	46.0916	-	UniMod	Methylthio	Beta-methylthiolation	H(2) C S
1184	SelCandM	Replacement of Sulfur with Selenium	47.94445	46.895	-	UniMod	Delta:S(-1)Se(1)	SelCandM	S(-1) Se
1418	Val2MetO	Val->Met, oxidized	47.966987	\N	-	PNNL		\N	S O
1008	Plus3Oxy	Three O16 Additions	47.984745	47.9982	-	UniMod	Trioxidation	Three_O16	O(3)
1193	Unknown1	Unknown modification 1 from Sisi	49	\N	-	PNNL		Unknown1	\N
1537	IronAdduct	Replacement of 3 protons with Iron	52.911464	52.8212	-	UniMod	Cation:Fe[III]	\N	H(-3) Fe
1451	MDA54	MDA adduct +54	54.010567	\N	-	UniMod	Delta:H(2)C(3)O(1)	MDA54	H(2) C(3) O
1192	NO2+10Da	NO2 Addition (Nitration), plus 10 Da shift	54.9851	54.9976	-	PNNL		Nitration with 10 Da shift	\N
1215	Propnyl	Propionate labeling reagent, light form	56.026215	56.063301	-	UniMod	Propionyl	Propionyl_light	H(4) C(3) O
1261	ChloroAA	Chloroacetamidine	56.0374464	56.06664	-	PNNL		CAA	H4 C2 N2
1561	Diethyl	Diethylation, analogous to dimethylation	56.0626	56.1063	-	UniMod	Diethyl	Diethylation	H(8) C(4)
1014	IodoAcet	Iodoacetamide Alkylation	57.021465	57.0513	-	UniMod	Carbamidomethyl	IodoAcet	H(3) C(2) N O
1055	IodoAcid	Iodoacetic Acid Alkylation	58.005478	58.0361	-	UniMod	Carboxymethyl	IodoAcid	H(2) C(2) O(2)
1324	N15_CAlk	15N-labeled cysteine that is alkylated	58.01854	58.0447	C	PNNL		N15_CAlk	H3 C2 O 15N
1362	+58.9895	Remove Carbamidomethyl and add Succinate	58.9895	\N	-	PNNL		\N	C2 H1 N(-1) O3
1560	Propnyl_C13	Propionate labeling reagent, heavy form	59.036279	59.0412	-	UniMod	Propionyl:13C(3)	Propionyl_heavy	H(4) 13C(3) O
1415	Val2MetF	Val->Met, then formylation	59.966987	\N	-	PNNL		\N	C O S
1562	Diethyl_C13	Diethylation, heavy form	60.076019	60.1197	-	PNNL	Diethyl:13C(4)	\N	H(8) 13C(4)
1358	CysHvAlk	3C131N15 Cysteine lus iodoacetamide alkyltion	61.0286	\N	-	PNNL		\N	\N
1422	L2MFrmOx	Leu->Met, then formylation, then oxidation	61.9462528	\N	-	PNNL		\N	H(-2) O(2) S
1557	CitrButanedione	Citrulline + 2,3-Butanedione	67.0183888	67.06602	-	PNNL		\N	C(4) H(3) O
1469	Crotonyl	Crotonylation	68.026215	\N	-	UniMod	Crotonyl	Crotonylation	H(4) C(4) O
1376	Butyryl	Butyrylation	70.041862	70.08984	-	UniMod	Butyryl	\N	H(6) C(4) O
1284	Acrylmid	Acrylimide adduct	71.037117	71.0779	-	UniMod	Propionamide	Propionamide	H(5) C(3) N O
1385	Sulfydrl	Sulfhydryl addition	73.9826362	74.10268	-	PNNL		Sulfhydryl	C(2) H(2) O1S
1419	V2MFrmOx	Val->Met, then formylation, then oxidiation	75.961902	\N	-	PNNL		\N	C O(2) S
1045	EDT_Addn	EDT Addition	75.98053	76.1838	-	UniMod	Ethanedithiol	EDT_Addn	H(4) C(2) O(-1) S(2)
1180	Bromo	Bromination	77.910507	78.8961	-	UniMod	Bromo	Bromo	H(-1) Br
1481	Se78	Selenium 78	77.9173	\N	-	PNNL		\N	Se
1175	Furylium	Fructosamine fragmentation product (loss of 3H2O and HCHO)	78.01057	78.0688	-	PNNL		Furylium	\N
1482	Se80	Selenium 80	79.9166	\N	-	PNNL		\N	Se
1010	Phosph	Phosphorylation	79.966331	79.9799	-	UniMod	Phospho	Phosph	H O(3) P
1205	Sulfate	Addition of SO4 followed by water loss on STY	80.9663	\N	-	PNNL		SO4 addn then water loss	\N
1167	DiAcet_K	Twice acetylated Lysine	84.0212	\N	-	PNNL		DiAcet_K	\N
1244	GEEster	Esterification with GEE	85.0528	85.1045	-	UniMod	NEIAA	N-ethyl iodoacetamide-d0	H(7) C(4) N O
1222	SelCIAM	Selenocysteine plus Iodoacetamide	85.9475	\N	-	PNNL		\N	\N
1471	PhosO18	O18-based phosphorylation	85.97908	\N	-	PNNL		Phosph O18	H(1) 18O(3) P(1)
1553	Xlink_DTSSP	Dithiobis[succinimidylpropionate]	85.982635	86.1124	-	UniMod	Xlink:DTSSP	DSP	H(2) C(3) O S
1399	Hypusine	replacement of Lysine	87.068414	87.1204	-	UniMod	hypusine	\N	H(9) C(4) N O
1160	NHS_SS	Sulfo-NHS-SS-Biotin (Xlink:DTSSP[88], Thioacyl, cleaved and reduced DSP/DTSSP crosslinker)	87.998285	88.1283	-	UniMod	Xlink:DTSSP[88]	DSP	H(4) C(3) O S
1074	SBEDBait	Sulfo SBED Bait	88.01	0	-	PNNL		Sulfo SBED Bait	\N
1229	SATADeAc	De-Acetylation of SATA	88.9935	\N	-	PNNL		\N	\N
1547	S-Carbamidomethyl	S-Carbamidomethyl	88.9935348	89.11736	-	PNNL	S-Carbamidomethyl	\N	H(3) C(2) N O S
1123	Biotinyl	Biotin Addition (bare biotin; do not use)	89.0061	0	-	PNNL		Biotinyl	\N
1447	Acrolein	Acrolein addition +94	94.041865	94.1112	-	UniMod		\N	H(6) C(6) O
1330	CysA95	Probe addition of 95.0371 Da to Cysteine	95.0371	\N	-	PNNL		\N	\N
1494	C6H7O	ATP probe on Lysine	95.0496872	95.119	-	PNNL		\N	C(6) H(7) O
1071	PhosphH	Phosph H (Thiophosphorylation)	95.943489	96.0455	-	UniMod	Thiophospho	Thiophospho	H O(2) P S
1227	NH2SO3	Aminotyrosine derivative N-substituted with -SO3	95.97554	96.08682	-	PNNL		Aminotyrosine SO3	\N
1297	DSDEG	DSDEG modification of lysine	96.0211	\N	-	PNNL		\N	\N
1028	Ubiq_L	Ubiquitination Light (Succinic anhydride)	100.016045	100.0728	-	UniMod	Succinyl	Ubiq_L	H(4) C(4) O(3)
1275	Benzam	Benzamidination (+C7H5N1) of primary amines	103.0422	\N	-			\N	\N
1274	Picolinm	Picolinamidination (+C6H4N2) of primary amines	104.0375	\N	-			\N	\N
1134	Ubiq_H	Ubiquitination Heavy (Succinic anhydride, heavy)	104.041153	104.0974	-	UniMod	Succinyl:2H(4)	Ubiq_H	2H(4) C(4) O(3)
1223	SeIodo	Iodoacetamide and Sulfur->Seleneium	104.965912	103.946297	-	UniMod	SecCarbamidomethyl	\N	H(3) C(2) N O S(-1) Se
1224	EthPhos	O-Ethylphosphorylation	107.997627	108.033096	-	UniMod	Ethylphosphate	MonoEthyl_Phosph	H(5) C(2) O(3) P
1176	Pyrylium	Fructosamine fragmentation product (loss of 3H2O from 162.0528)	108.021126	108.0948	-	UniMod	HydroxymethylOP	Pyrylium	H(4) C(6) O(2)
1543	DTDP	Dithiodipyridine	108.9986198	109.15006	-	PNNL	Dithiodipyridine	\N	H(3) C(5) S N
1454	DACT	Diaminochlorotriazine	110.0466684	\N	-	PNNL		\N	H(4) C(3) N(5)
1021	Ubiq_02	Ubiquitinylation (on Lys)	114.042931	114.1026	-	UniMod	GG	GlyGly	H(6) C(4) N(2) O(2)
1246	EGS	Addition of EGS cross linker to Lys	115.02694	115.08744	-	PNNL		EGS cross linker	C4 H5 N O3
1136	SATA_Lgt	SATA Addition Light	115.9932	0	-	PNNL		SATA_Light	\N
1200	Sucinate	Succinate on Cysteine	116.010956	116.0722	-	UniMod	2-succinyl	Sucinate	H(4) C(4) O(4)
1269	CystamIA	C-terminal Cystamine treated with iodoacetamide	116.0408	\N	-	PNNL		\N	\N
1153	Cys_EDTI	EDT+Iodo attached to a Cysteine	117.024834	\N	-	UniMod	HCysThiolactone	Cys EDT+Iodo	H(7) C(4) N O S
1312	Cystnyl	cysteinylation	119.004097	\N	-	UniMod	Cysteinyl	\N	H(5) C(3) N O(2) S
1142	C12_PIC	C12 Phenylisocyanate	119.037117	119.1207	-	UniMod	Phenylisocyanate	C12 Phenylisocyanate	H(5) C(7) N O
1548	SS-Carbamidomethyl	SS-Carbamidomethyl	120.9656068	121.18336	-	PNNL	SS-Carbamidomethyl	\N	H(3) C(2) N O S(2)
1251	NEM	Nethylmaleimide	125.047676	125.1253	-	UniMod	Nethylmaleimide	N-ethylmaleimide on cysteines	H(7) C(6) N O(2)
1144	C13_PIC	C13 Phenylisocyanate	125.0572	0	-	PNNL		C13 Phenylisocyanate	\N
1449	DiEtP-10	Fake mod: O-Diethylphosphorylation minus 10	126.028931	126.086197	-	PNNL		\N	\N
1168	TriAcetK	Triple Acetylation Lysine	126.0318	\N	-	PNNL		Triple Acetylation	\N
1526	Itaconate128	Itaconate, 128 Da, likely the wrong mod mass	128.0109584	128.08286	-	PNNL	Itaconate	\N	H(4) C(5) O(4)
1508	MonoGlu	Monoglutamyl	129.042593	129.114	-	UniMod	Glu	-Glu-	H(7) C(5) N O(3)
1137	SATA_Hvy	SATA Addition Heavy	129.9963	0	-	PNNL		SATA Heavy	\N
1527	MonoMethSuccinyl	Itaconatic acid; S-(2-monomethylsuccinyl) cysteine	130.0266076	130.09874	-	UniMod	2-monomethylsuccinyl	\N	H(6) C(5) O(4)
1542	Itaconate	S-(2-monomethylsuccinyl) cysteine; also cysteine itaconate	130.026609	130.0987	-	UniMod	2-monomethylsuccinyl	Itaconate	H(6) C(5) O(4)
1409	NEM_2H5	Nethylmaleimide with 5 deuteriums	130.079062	130.1561	-	UniMod	NEM:2H(5)	\N	H(2) 2H(5) C(6) N O(2)
1151	SATA_Alk	SATA Alkylated	131.0041	131.15404	-	PNNL		SATA Alkylated	\N
1245	Ox+Fumrt	Oxidation plus Fumarate/succinate	132.005875	132.0716	-	UniMod	Xlink:DST	OxPlusFumarate	H(4) C(4) O(5)
1410	Pentose	Pentose	132.0422568	\N	-	PNNL	Pentose	Pentose	H(8) C(5) O(4)
1505	Benzoth	Benzothiazole	132.9986198	133.17146	-	PNNL	Benzothiazole		H(3) C(7) N S
1152	EDT+Iodo	EDT with Iodoacetamide	133.002	\N	-	PNNL		EDT+Iodo	\N
1230	Cystamin	Cystamine modification	134.0336	\N	-	PNNL		\N	\N
1240	PITC	-NH2(Nterm) to -NHCSNHC6H5	135.01427	135.1873	-	PNNL		PITC	H5 C7 N S
1068	PhIATMod	PhIAT Mod1	136.001663	136.235703	-	UniMod	DTT_ST	PhIATMod	H(8) C(4) O S(2)
1280	PYITC	PYITC (+C6H4N2S1) of primary amines	136.0095	\N	-			\N	\N
1225	DiEtPhos	O-Diethylphosphorylation	136.028931	136.086197	-	UniMod	Diethylphosphate	DiEthyl_Phosph	H(9) C(4) O(3) P
1314	C137	Click addition to Cys, 137.0841 Da	137.0841	\N	-	PNNL		\N	\N
1558	CitrCysteamine	Citrulline + 2,3-Butanedione + Cysteamine	142.0326578	142.19986	-	PNNL		\N	C(6) H(8) O N S
1439	+142.066	C10H8N for MSPathfinder	142.0656708	\N	-	PNNL		\N	H(8) C(10) N
1228	DTBP_Alk	DTBP coupled to iodoacetamide, reacts with primary amines	144.03573	144.1959	-	PNNL		DTBP+Iodo	\N
1179	itrac	itrac (iTRAQ)	144.102066	144.1544	-	UniMod	iTRAQ4plex	iTRAQ	H(12) C(4) 13C(3) N 15N O
1232	AcNHS-SS	acetylation of the Sulfo-NHS-SS-Biotin probe	145.019745	\N	-	UniMod	CAMthiopropanoyl	Ac-Sulfo-NHS-SS-Biotin	H(7) C(5) N O(2) S
1171	SATAIodo	SATA with Iodoacetylation	146.015	\N	-	PNNL		SATA with Iodoacet	\N
1450	DiEtP+10	Fake mod: O-Diethylphosphorylation plus 10	146.028931	146.086197	-	PNNL		\N	\N
1411	DeoxyHex	Deoxyhexose	146.057906	\N	-	PNNL	DeoxyHex	Deoxyhexose	H(10) C(6) O(4)
1273	Phthalyl	Phthalylation (+C8H3O3) of primary amines	148.016	\N	-	PNNL		\N	\N
1504	+148.052	C9H8O2	148.052427	148.15862	-	PNNL	C9H8O2		H(8) C(9) O(2)
1248	BS3Olnk	BS3 crosslinking reagent, type 0 cross-link	156.078644	\N	-	UniMod	Xlink:DSS	\N	H(12) C(8) O(3)
1396	ValGly	Addition of ValGly from UFM1	156.089873	\N	-	PNNL		ValGly	H(12) C(7) N(2) O(2)
1460	M2HPGBio	Methionine replaced by HPG and enriched using a cleavable biotin linker	156.0977358	\N	-	PNNL	MetToHPGBiotin	\N	H(8) C(9) N(4) O(1) S(-1)
1486	BtnHBGDz	Substitution of HBG for Met during translation, followed by Biotin click chemistry	156.097737	156.12018	-	PNNL	BiotinHBGDiazo	\N	C(9) H(8) N(4) O(1) S(-1)
1431	NEMsulf	N-ethylmaleimide persulfide	157.019749	\N	-	UniMod	NEMsulfur	S-Nethylmaleimide	H(7) C(6) N O(2) S
1448	FormylM	Addition of formylated Methionine	159.0354	159.2072	-	UniMod	FormylMet	\N	H(9) C(6) N O(2) S
1239	PEIAA	-SH to -S-CH2CONHCHCH3C6H5	161.0841	161.2005	-	PNNL		PEIAA	H11 C10 N O
1054	Hexose	Hexose Addition (also for Amadori glycation)	162.052826	162.1406	-	UniMod	Hex	Hexose	C(6) H(10) O(5)
1506	OxBenzo	Oxidized Benzothiazole	164.9884498	165.17026	-	PNNL	Oxidized_Benzothiazole		H(3) C(7) O(2) N S
1514	CysPAT	Alkylation with (2-(2-iodoacetamido)ethyl)phosphonic acid	165.01909	165.084421	-	PNNL		\N	H(8) C(4) N O(4) P
1279	PEITC	PEITC (+C8H14N2S1) of primary amines	170.0878	\N	-			\N	\N
1012	SP_Light	SP Light Label	170.1055	0	-	PNNL		SP_Light	\N
1277	MEITC	MEITC (+C7H12N2S1O1) of primary amines	172.067	\N	-			\N	\N
1129	Ubiq_L03	Special Ubiquination Light	172.0942	0	-	PNNL		Ubiq_L03	\N
1554	Xlink_DTSSP_174	Intact DSP/DTSSP crosslinker	173.980921	174.2406	-	UniMod	Xlink:DTSSP[174]	DSP	H(6) C(6) O(2) S(2)
1549	Lyso-BCN	Lyso-BCN	176.0837252	176.21178	-	PNNL		\N	C(11) H(12) O(2)
1135	Ubiq_H03	Special Ubiquination Heavy	176.1255	0	-	PNNL		Ubiq_H03	\N
1513	HPE-IAM	Cysteine plus N-Iodoacetyltyramine (https://pubchem.ncbi.nlm.nih.gov/compound/193901)	177.0789746	177.19988	-	PNNL	N-Iodoacetyltyramine	ß-(4-Hydroxyphenyl)ethyl iodoacetamide	H(11) C(10) N O(2)
1048	EDT_D0	EDT_D0-SP	177.1055	0	-	PNNL		EDT_D0	\N
1013	SP_Heavy	SP Heavy Label	177.1583	0	-	PNNL		SP_Heavy	\N
1241	DPITC	-NH2(Nterm) to -NHCSNHC6H4NCH3CH3	178.0565	178.2552	-	PNNL		DPITC	H(10) C(9) N(2) S
1502	+178.063	C10H10O3	178.062991	178.1846	-	PNNL	C10H10O3		H(10) C(10) O(3)
1342	LysPC	PC modification of Lysine	181.1089	\N	-	PNNL		\N	\N
1022	MTSLAddn	MTSL Label	184.079605	184.278595	-	UniMod	MTSL	MTSLAddn	H(14) C(9) N O S
1310	FMArgnyl	formylated arginylation	184.096	\N	-	PNNL		\N	\N
1307	DMarginl	dimethylated arginylation of peptide N-terminus	184.1324	\N	-	PNNL		\N	\N
1440	+185.141	C10H19NO2 for MSPathfinder	185.1415714	\N	-	PNNL		\N	C(10) H(19) N O(2)
1278	MPITC	MPITC (+C8H14N2O1S1) of primary amines	186.0827	\N	-			\N	\N
1006	Lipoyl	Lipoyl addition	188.032959	188.3103	-	UniMod	Lipoyl	Lipoyl	H(12) C(8) O S(2)
1517	NEM_S2	N-ethylmaleimide polysulfide	188.99182	\N	-	PNNL	NEM_S2	S2-Nethylmaleimide	H(7) C(6) N O(2) S2
1238	BPIAA	-SH to -S-CH2CONHC6H4CH2CH2CH2CH3	189.11536	189.25364	-	PNNL		BPIAA	H15 C12 N O
1326	Cys190	190.0994 Da SA probe for Cysteine	190.0994	\N	-	PNNL		\N	\N
1555	Xlink_DTSSP_192	Water quenched monolink of DSP/DTSSP crosslinker	191.991486	192.2559	-	UniMod	Xlink:DTSSP[192]	DSP	H(8) C(6) O(3) S(2)
1219	Mercury	Mercury Hg(II) adduct	199.9549	\N	-	PNNL		\N	\N
1053	Hexosam	N-Acetylhexosamine Addition	203.079376	203.1925	-	UniMod	HexNAc	Hexosam	H(13) C(8) N O(5)
1510	OGlcNAc	O-GlcNAcylation (wrong mod mass; use Hexosam aka HexNAc)	204.0871934	204.2005	-	PNNL		OGlcNAc	H(14) C(8) N O(5)
1201	FarnesC	Addition of H24 and C15 to cysteine	204.3511	\N	-	PNNL		FarnesC	\N
1281	DEITC	DEITC (+C11H14N2S1) of primary amines	206.0878	\N	-			\N	\N
1503	+208.074	C11H12O4	208.073555	208.21058	-	PNNL	C11H12O4		H(12) C(11) O(4)
1515	HPE-IAMS	Cysteine plus N-Iodoacetyltyramine and S	209.0510466	\N	-	PNNL	N-Iodoacetyltyramine_S	\N	H(11) C(10) N O(2) S
1383	Myristyl	Myristoylation	210.198364	210.35564	-	UniMod	Myristoyl	Myristoylation	H(26) C(14) O
1528	PhosphoRibose	Phosphoribosylation	212.008589	\N	-	UniMod	phosphoRibosyl	\N	H(9) C(5) O(7) P
1242	SPITC	-NH2(Nterm) to -NHCSNHC6H4SO3H	214.971085	215.249496	-	UniMod	SPITC	SPITC	H(5) C(7) N O(3) S(2)
1371	MethylHg	methyl mercury adduct to cysteine	214.9784	\N	-	PNNL		\N	\N
1268	TMT0Tag	Thermo Tandem Mass Tag 0 (zero) label	224.152478	\N	-	UniMod	TMT	\N	H(20) C(12) N(2) O(2)
1489	TMT2Tag	Thermo Tandem Mass Tag 2 label (duplex)	225.155833	\N	-	UniMod	TMT2plex	\N	H(20) C(11) 13C N(2) O(2)
1078	SulfoNHS	Sulfo-NHS-Biotin Addition	226.077591	226.2954	-	UniMod	Biotin	Sulfo-NHS-Biotin	H(14) C(10) N(2) O(2) S
1539	Biotin	Biotinylation	226.0775944	226.29644	-	UniMod	Biotin	Biotinylation	H(14) C(10) N(2) O(2) S
1041	ICAT_C12	Cleavable ICAT C12	227.126984	227.2603	-	UniMod	ICAT-C	ICAT_C12	H(17) C(10) N(3) O(3)
1550	Lyso-BCN-C6H4	Lyso-BCN-C6H4	228.1150236	228.28634	-	PNNL		\N	C(15) H(16) O(2)
1128	Ubiq_L02	Special Light Ubiquination	229.127	0	-	PNNL		Ubiq_L02	\N
1267	TMT6Tag	Thermo Tandem Mass Tag 6 label (sixplex). Note that TMT10 and TMT11 have the same monoisotopic mass as TMT6.	229.162933	\N	-	UniMod	TMT6plex	\N	H(20) C(8) 13C(4) N 15N O(2)
1216	EthylHG	Ethyl mercuric (C2H5Hg - H) modification primarily on Cysteine	230.0019	\N	-	PNNL		\N	\N
1459	SMILS231	Click SMILES: OC1=CC=C(NC(CCCC#C)=O)C=C1C(Xaa)OH	231.08954	\N	-	PNNL		SMILES_231	H(13) C(13) O(3) N
1458	SMILS233	Click SMILES: OC1=CC=C(NC(CCCC#C)=O)C=C1C(Xaa)F	233.0852	\N	-	PNNL		SMILES_233	H(12) C(13) O(2) F N
1133	Ubiq_H02	Special Heavy Ubiquination	233.1583	0	-	PNNL		Ubiq_H02	\N
1042	ICAT_C13	Cleavable ICAT C13	236.157181	236.1942	-	UniMod	ICAT-C:13C(9)	ICAT_C13	H(17) C 13C(9) N(3) O(3)
1367	palmtlic	Cys-palmitoleic acid S-linked, C16H28O	236.21402	\N	-	UniMod	Palmitoleyl	\N	H(28) C(16) O
1512	palmtoyl	Palmitoylation	238.229666	\N	-	UniMod	Palmitoyl	\N	H(30) C(16) O
1516	HPE-IASS	Cysteine plus N-Iodoacetyltyramine and S2	241.02311	\N	-	PNNL	N-Iodoacetylthramine_S2	\N	H(11) C(10) N O(2) S(2)
1206	UbsFrag	Fragment of ubiquitin	242.1378	\N	-	PNNL		Ubiquitin fragment	\N
1377	PUP	Pupylation	243.085526	243.21674	-	UniMod	pupylation	\N	H(13) C(9) N(3) O(5)
1018	EDPLight	EDP-SP Light	246.0819	0	-	PNNL		EDPLight	\N
1394	SOHDynPC	SOH_Dyn2_PC	248.12733	\N	-	PNNL		\N	\N
1047	EDT_D0C7	EDT_D0-SP_C7	253.0819	0	-	PNNL		EDT_D0C7	\N
1019	EDPHeavy	EDP-SP Heavy	253.1032	0	-	PNNL		EDPHeavy	\N
1309	SCArgnyl	succinylated arginylation	256.1172	\N	-	PNNL		\N	\N
1046	EDT_D4C7	EDT_D4-SP_C7	257.0819	0	-	PNNL		EDT_D4C7	\N
1368	vaccenic	Cys-vaccenic acid S-linked, C18H32O	264.2453	\N	-	PNNL		\N	\N
1456	BnzPyrO1	Benzo(a)pyrene-induced DNA Base Modification with O1	266.073161	\N	-	PNNL		\N	H(10) C(20) O(1)
1332	CysA269	Probe addition of 269.0946 Da to Cysteine	269.0946	\N	-	PNNL		\N	\N
1464	BiotnHBG	Substitution of HBG for Met during translation, followed by Biotin click chemistry	277.1828584	277.25864	-	PNNL	BiotinHBG	\N	C(12) H(19) N(7) O(3) S(-1)
1207	PMA	Phenyl mercuric acetate modification of thiols	278.0019	\N	-	PNNL		Phenyl mercuric acetate	\N
1457	BnzPyrO2	Benzo(a)pyrene-induced DNA Base Modification with O2	282.068076	\N	-	PNNL		\N	H(10) C(20) O(2)
1283	DABITC	DABITC (+C15H14N4S1) of primary amines	282.0939	\N	-			\N	\N
1435	MalABP-H	MalABP addition to Cysteine, minus H	282.1579492	\N	-	PNNL		\N	C(14) H(22) N(2) O(4)
1318	Cys282	Click addition of 282.158	282.158	\N	-	PNNL		\N	\N
1433	MalABP	MalABP addition to Cysteine	283.165773	\N	-	PNNL		\N	C(14) H(23) N(2) O(4)
1308	SATAarg	SATA labeled arginylation of peptide N-terminus	287.1052	\N	-	PNNL		\N	\N
1412	NeuAc	NeuAc	291.0954042	\N	-	UniMod	NeuAc	N-acetyl neuraminic acid	\N
1545	TMTPro0	TMTpro 0 label	295.189592	295.3773	-	UniMod	TMTpro_zero	\N	\N
1455	BenzPyrn	Benzo(a)pyrene-induced DNA Base Modification with O3	298.062991	\N	-	PNNL		\N	H(10) C(20) O(3)
1496	GST_ABP	GST-ABP probe modification of peptides	300.0506	\N	-	PNNL		\N	\N
1237	iTRAQ8	iTRAQ 8-Plex modification	304.205353	\N	-	UniMod	iTRAQ8plex	iTRAQ8	H(24) C(7) 13C(7) N(3) 15N O(3)
1509	TMT16Tag	Thermo Tandem Mass Tag 16 label; TMTpro	304.207146	304.3127	-	UniMod	TMTpro	\N	H(25) C(8) 13C(7) N 15N(2) O(3)
1453	PhosCyto	Phosphocytosine (CMP)	305.0412852	\N	-	PNNL	PhosphoCytosine	\N	H(12) C(9) N(3) O(7) P
1185	Gluthone	Glutathione disulfide	305.068156	305.307587	-	UniMod	Glutathione	Glutathione	H(15) C(10) N(3) O(6) S
1305	PhosUrid	Phospho-Uridine (UMP)	306.025299	\N	-	UniMod	PhosphoUridine	\N	H(11) C(9) N(2) O(8) P
1413	NeuGc	NeuGc	307.0903183	\N	-	UniMod	NeuGc	N-glycoyl neuraminic acid	\N
1177	Farnesyl	Farnesylation of sulfur containing residues	307.197	\N	-	PNNL		Farnesyl	\N
1331	CysA311	Probe addition of 311.1052 Da to Cysteine	311.1052	\N	-	PNNL		\N	\N
1315	Cys311	Click additions to Cys, 311.1416 Da	311.1416	\N	-	PNNL		\N	\N
1446	Hex2	Two hex groups	324.105647	\N	-	UniMod	Hex(2)	\N	C(12) H(20) O(10)
1381	iodoTMT0	Thermo iodoTMT0 (zero) label	324.216156	\N	-	UniMod	iodoTMT	\N	H(28) C(16) N(4) O(3)
1333	CysA326	Probe addition of 326.1161 Da to Cysteine	326.1161	\N	-	PNNL		\N	\N
1304	PhosAden	Phospho-adenosine (AMP)	329.052521	\N	-	UniMod	Phosphoadenosine	\N	H(12) C(10) N(5) O(6) P
1382	iodoTMT6	Thermo iodoTMT6 (six) label	329.226593	\N	-	UniMod	iodoTMT6plex	\N	H(28) C(12) 13C(4) N(3) 15N O(3)
1556	LG-lactam-K	Levuglandinyl - lysine lactam adduct	332.19876	332.4339	-	Unimod	LG-lactam-K	\N	H(28) C(20) O(4)
1546	S-Glutathione	Glutathione trisulfide	337.040225	337.37472	-	PNNL	S-Glutathione	\N	H(15) C(10) N(3) O(6) S(2)
1040	NHSLCBio	NHS-LC-Biotin	339.161652	339.453	-	UniMod	NHS-LC-Biotin	NHSLCBio	H(25) C(16) N(3) O(3) S
1254	holoACP	phosphopantetheinylate addition to hydroxyl through phosphoester	340.3341	\N	-	PNNL		\N	\N
1488	TMT6Gly2	TMT6 Plex plus di-Gly left from Ubiquitinylation	343.20583	\N	-	PNNL		\N	\N
1452	PhosGuan	Phospho-guanosine (GMP)	345.047424	\N	-	UniMod	Phosphoguanosine	\N	H(12) C(10) N(5) O(7) P
1559	CitrMercapto	Citrulline + 2,3-Butanedione + Mercapto...	348.1527836	348.51004	-	PNNL		\N	C(13) H(26) O(2) N(5) S(2)
1317	Cys352	Click additions to Cys, 352.1522	353.1522	\N	-	PNNL		\N	\N
1397	Dyn2DZ	Dyn2_Diazo	354.16919	\N	-	PNNL	Dyn2DZ	Dyn2DZ	\N
1025	BioPeoAm	Biotin polyethyleneoxide (PEO) Amine	356.188202	356.4835	-	UniMod	Biotin-PEO-Amine	BioPeoAm	H(28) C(16) N(4) O(3) S
1329	Cys364	Click addition of 364.1569 Da	364.1569	\N	-	PNNL		\N	\N
1423	H1HNAc	Hex HexNAc	365.132196	\N	-	UniMod	Hex(1)HexNAc(1)	Hex HexNAc	\N
1316	Cys368	Click additions to Cys, 368.1631	368.1613	\N	-	PNNL		\N	\N
1341	LysTEV	TEV modification on Lysine	380.2046	\N	-	PNNL		\N	\N
1189	UbiqLRGG	Ubiquitination with LRGG rather than simply GG	383.228088	383.446014	-	UniMod	LeuArgGlyGly	Ubiq_LRGG	H(29) C(16) N(7) O(4)
1255	acetlACP	thiol acetylation of phosphopantetheinylate addition to hydroxyl	383.3787	\N	-	PNNL		\N	\N
1436	IAAABP-H	NCS_IAABP probe addition to Cysteine, minus H	393.1899762	\N	-	PNNL		\N	C(19) H(27) N(3) O(6)
1401	ABP_Ser1	Serine protease activity-based probe	393.2042	393.4321	-	PNNL	ABP_Ser1	ABP_Ser1	C(18) H(34) O(7) P
1434	IAAABP	NCS_IAABP probe addition to Cysteine	394.197801	\N	-	PNNL		\N	C(19) H(28) N(3) O(6)
1327	Cys406	406.1675 Da SA addition to Cysteine	406.1675	\N	-	PNNL		\N	\N
1294	MALnoAlk	MALABP addition to Cysteine in the face of static alkylation of	408.2372	\N	-	PNNL		\N	\N
1256	btoylACP	thiol acylation of phosphopantetheinylate addition to hydroxyl t	409.416	\N	-	PNNL		\N	\N
1257	btrylACP	thiol acylation of phosphopantetheinylate addition to hydroxyl t	411.4319	\N	-	PNNL		\N	\N
1002	PEO	PEO Addition	414.193695	414.5196	-	UniMod	PEO-Iodoacetyl-LC-Biotin	PEO	H(30) C(18) N(4) O(5) S
1540	TMT16Gly2	16-plex TMT plus di-Gly left from Ubiquitinylation	418.25008	\N	-	PNNL		\N	\N
1328	Cys421	421.1783 Da addition to Cysteine	421.1783	\N	-	PNNL		\N	\N
1258	acatlACP	thiol aceto-acylation of phosphopantetheinylate addition to hydr	425.4154	\N	-	PNNL		\N	\N
1259	malnlACP	malonylation of phosphopantetheinylate addition to hydroxyl thro	427.3882	\N	-	PNNL		\N	\N
1065	Oxid_PEO	Oxidized PEO	430.1886	0	-	PNNL		Oxid_PEO	\N
1500	Ibrutnib	Ibrutinib addition	440.1960644	440.4973	-	PNNL	Ibrutinib	\N	H(24) C(25) N(6) O(2)
1000	ICAT_D0	ICAT d0	442.225006	442.572815	-	UniMod	ICAT-D	ICAT_D0	H(34) C(20) N(4) O(5) S
1066	PEO4Addn	PEO4 Addition	442.2553	0	-	PNNL		PEO4Addn	\N
1531	HexNAcGlycoTrans	Glycotransferred O-GlcNac	447.160135	447.3974	-	PNNL		HexNAcGlycoTrans	H(25) C(16) N(5) O(10)
1001	ICAT_D8	ICAT d8	450.275208	450.6221	-	UniMod	ICAT-D:2H(8)	ICAT_D8	H26 2H(8) C20 N4 O5 S
1395	SOHDynDZ	SOH_Dyn2_Diazo	455.21687	\N	-	PNNL		\N	\N
1319	Cys465	Click addition of 456.2155	456.2155	\N	-	PNNL		\N	\N
1501	Acalbnib	Acalabrutinib addition	465.1913138	465.5068	-	PNNL	Acalabrutinib	\N	H(23) C(26) N(7) O(2)
1286	MALABP2	MalABP addition to Cysteine (variant 2)	465.258721	465.5434	-	PNNL		\N	C(22) H(35) N(5) O(6)
1491	B12ABPa	B12 ABP Carbene Mode, fragment a	469.208699	\N	-	PNNL	B12_ABP_Carbene_FragmentA	B12_ABP_Carbene_FragmentA	C(24) H(29) N(4) O(6)
1533	SMycothionyl	S-mycothionylation	484.1362888	484.4765	-	PNNL		\N	C(17) H(28) N(2) O(12) S
1202	Sumoylat	Sumoylation of Lys or Arg	484.228149	\N	-	UniMod	EQIGG	Sumoylation	H(32) C(20) N(6) O(8)
1441	Hex3	Three hex groups	486.158471	\N	-	UniMod	Hex(3)	\N	C(18) H(30) O(15)
1003	PhIATD0	PhIAT d0	490.174225	490.7034	-	UniMod	EDT-iodoacetyl-PEO-biotin	PhIATD0	H(34) C(20) N(4) O(4) S(3)
1285	FP2	FP2 addition onto Serine	491.2760232	491.558661	-	PNNL		\N	C(22) H(42) N(3) O(7) P
1004	PhIATD4	PhIAT d4	494.1993	494.7281	-	PNNL		PhIATD4	\N
1069	TrypPD4	Tryp_PhIATd4	494.74	0	-	PNNL		Tryp_PhIATd4	\N
1320	Cys498	Click addition of 497.2261	498.2261	\N	-	PNNL		\N	\N
1203	SumoEstr	Methyl esterified Sumoylation of Lys or Met	498.2417	\N	-	PNNL		Methyl esterified Sumoylation	\N
1253	PCGalNAz	PC Gal NAz mod	502.202332	\N	-	UniMod	AMTzHexNAc2	\N	H(30) C(19) N(6) O(10)
1321	Cys513	Click addition of 513.2237	513.237	\N	-	PNNL		\N	\N
1424	H2HNac	Hex(2) HexNAc	527.185	\N	-	PNNL	Hex(2)HexNAc(1)	Hex(2) HexNAc	\N
1380	DOTA_Eu	Absolute quantification with DOTA and 151Eu	534.0765	\N	-	UniMod	DOTA_Eu	\N	H(23) C(16) N(4) O(7) 151Eu
1196	ClickBio	Click-Bio enrichment compound	539.252	\N	-	PNNL		ClickBio	\N
1306	ADPRibos	ADP Ribose addition (UniMod #231)	541.061096	\N	-	UniMod	ADP-Ribosyl	\N	H(21) C(15) N(5) O(13) P(2)
1483	ABP_FP2	Probe addition of 542.25 Da to Serine	542.2505384	\N	-	PNNL		\N	C(24) H(39) N(4) O(8) P
1075	SBEDCapt	Sulfo SBED Capture	547.22	0	-	PNNL		Sulfo SBED Capture	\N
1493	B12ABPc	B12 ABP Carbene Mode, fragment c (mass difference between 1547.6618 and 997.4806 in Lindsey-B12-ABP-1-20HCD.raw)	550.1812	\N	-	PNNL	B12_ABP_Carbene_FragmentC	B12_ABP_Carbene_FragmentC	C(24) H(31) N(4) O(9) P
1067	GluCPD4	GluC_PhIATd4	550.1953	0	-	PNNL		GluCPD4	\N
1265	ATW8TEV	ATW8 Probe, TEV, C27H48N8O5	564.3748	\N	-	PNNL		\N	\N
1438	IAAABPTU	NCS_IAAABP_TEV_1->3 probe, minus H	567.3128796	\N	-	PNNL		\N	C(24) H(41) N(9) O(7)
1363	IAAABPTV	NCS_IAAABP_TEV_1->3 probe addition to Cysteine	568.3207	568.6567	-	PNNL		\N	C24 H42 N9 O7
1260	TMPPAc	TMPP-Ac	572.181152	572.5401	-	UniMod	TMPP-Ac	tris(2,4,6-trimethoxyphenyl)phosphonium acetic acid	H(33) C(29) O(10) P
1191	Lipid2	S-diaglycerol-L-cysteine lipid modification alternative	576.51178	576.933411	-	UniMod	Diacylglycerol	S-diacylglycerol-L-cysteine	H(68) C(37) O(4)
1264	2ENTEV	2EN probe, TEV, C29H38N8O5	578.2965	\N	-	PNNL		\N	\N
1059	NHSPEO4	NHS PEO4	588.2465	0	-	PNNL		NHSPEO4	\N
1524	BC-558-2	Alkylation with BC-558-2	598.2613628	\N	C	PNNL		\N	H(38) C(34) N(4) O(4) S
1263	ATW8BtnS	ATW8 probe, Biotin stripped, C30H50N7O4S	604.3645	\N	-	PNNL		\N	\N
1052	Heme_Sas	Heme Sasha Corr	614.1819	0	-	PNNL		Heme_Sas	\N
1035	Heme_615	Heme 615 adduct	615.169458	615.4795	-	PNNL	Heme_615	Heme_615	H31 C34 N4 O4 Fe
1005	HemeAddn	Heme adduct	616.177307	616.487305	-	UniMod	Heme	HemeAddn	H(32) C(34) N(4) O(4) Fe
1023	Heme_617	Heme 617 adduct	617	0	-	PNNL		Heme_617	\N
1262	2ENBtnSt	2EN probe, Biotin Stripped, C32H40N7O4S	618.2863	\N	-	PNNL		\N	\N
1485	ABP_TEV2	Activity based proteomics TEV-FP2 tag for serine	633.3250968	633.674861	-	PNNL	ABP_TEV_FP2	ABP_TEV_FP2	H(48) C(26) N(7) O(9) (P)
1442	Hex4	Four hex groups	648.211294	\N	-	UniMod	Hex(4)	\N	C(24) H(40) O(20)
1300	GalNAFuc	PCGalNAz_Fuc	648.2603	\N	-	PNNL		\N	\N
1386	HHN	Hex HexNAc NeuAc	656.2276	\N	-	UniMod	Hex(1)HexNAc(1)NeuAc(1)	HHN	\N
1301	GalNAMan	PCGalNAz_Man	664.2551	\N	-	PNNL		\N	\N
1400	ABP_TEV	Activity based proteomics TEV tag for serine	677.3513102	677.727421	-	PNNL	ABP_TEV	ABP_TEV	C28 H52 N7 O10 P
1437	MalABPTU	NCS_MalABP_TEV_1->3, minus H	678.3449066	\N	-	PNNL		\N	C(29) H(46) N(10) O(9)
1366	MalABPTV	NCS_MalABP_TEV_1->3	679.3527	679.7455	-	PNNL		\N	C29 H47 N10 O9
1190	Lipid1	S-diaglycerol-L-cysteine lipid modification	679.52	680.0774	-	PNNL	N-acyl-S-diaglyceryl-Cys	S-diacylglycerol-L-cysteine	\N
1425	H3HNAc	Hex(3) HexNAc	689.2378	\N	-	PNNL	Hex(3)HexNAc(1)	Hex(3) HexNAc	\N
1247	CLIPOlnk	CLIP reagent, biotinylated, type 0 cross-link	694.2744	\N	-	PNNL		\N	\N
1432	GalNADBC	DBCO_GalNAz	723.28641	\N	-	PNNL		\N	\N
1313	DECLIP	Dead end CLIP reagent	740.3162	\N	-	PNNL		\N	\N
1426	H3GlNAc2	Man3-GlcNAc2	892.3172	\N	-	UniMod	Hex(3)HexNAc(2)	Hex(3) HexNAc(2)	\N
1370	Gly1024	Defucosylated version of Gly1170	1024.3594	\N	-	PNNL		Defucosylated Gly 1170	C39 H64 O29 N2
1427	H4GlNAc2	Man4-GlcNAc2	1054.370039	\N	-	UniMod	Hex(4)HexNAc(2)	Hex(4) HexNAc(2)	C(40) H(66) O(30) N(2)
1369	Gly1170	Glycan Man3-Xyl-GlcNAc2-Fuc	1170.4174	\N	-	PNNL		Glycan 1170	C45 H74 O33 N2
1532	HexNAcBiotinConj	Biotin-conjugated O-GlcNac	1179.4628066	1180.22292	-	PNNL		HexNAcBiotinConj	H(71) C(49) N(12) O(20) S
1226	Taxol	Addition of Taxol to Cys	1206.4685	1207.27816	-	PNNL		\N	\N
1428	H5GlNAc2	Man5-GlcNAc2	1216.4228426	\N	-	UniMod	Hex(5)HexNAc(2)	N-glycan	C(46) H(76) O(35) N(2)
1484	TEV-FP2	Probe addition of FP2-Tri-N3 to Serine	1287.612673	\N	-	PNNL		\N	C(63) H(90) N(11) O(14) P S
1429	H6GlNAc2	Man6-GlcNac2	1378.4756	\N	-	PNNL	Hex(6)HexNAc(2)	Hex(6) HexNAc(2)	C(36) H(60) O(30)
1466	GlyG0F	Glycosylation G0F	1444.5338442	\N	-	UniMod	dHex(1)Hex(3)HexNAc(4)	\N	C(56) H(92) O(39) N(4)
1492	B12ABPb	B12 ABP Carbene Mode, fragment b	1462.728798	\N	-	PNNL	B12_ABP_Carbene_FragmentB	B12_ABP_Carbene_FragmentB	C(72) H(101) N(15) O(16) P
1443	Hex7HNA2	Hex(7) HexNAc(2)	1540.52851	\N	-	UniMod	Hex(7)HexNAc(2)	\N	Hex(7) HexNAc(2)
1490	B12ABP	B12 ABP Carbene Mode	1545.64942	1546.57236	-	PNNL	B12_ABP_Carbene	B12_ABP_Carbene	C(73) H(99) Co N(16) O(16) P
1467	GlyG1F	Glycosylation G1F	1606.5866652	\N	-	UniMod	dHex(1)Hex(4)HexNAc(4)	\N	C(62) H(102) O(44) N(4)
1204	UbqLFrag	Fragment of Ubiquitin retained by ubiquination	1641.775	\N	-	PNNL		Ubiquitination fragment	\N
1444	Hex8HNA2	Hex(8) HexNAc(2)	1702.581333	\N	-	UniMod	Hex(8)HexNAc(2)	\N	Hex(8) HexNAc(2)
1445	Hex9HNA2	Hex(9) HexNAc(2)	1864.634157	\N	-	UniMod	Hex(9)HexNAc(2)	\N	Hex(9) HexNAc(2)
\.


--
-- Name: t_mass_correction_factors_mass_correction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_mass_correction_factors_mass_correction_id_seq', 1570, true);


--
-- PostgreSQL database dump complete
--

