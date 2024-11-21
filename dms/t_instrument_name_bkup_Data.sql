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
-- Data for Name: t_instrument_name_bkup; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_name_bkup (instrument_id, instrument, instrument_class, instrument_group, source_path_id, storage_path_id, capture_method, status, room_number, description, created) FROM stdin;
35	11T_Aux2	BrukerFTMS	FT_ZippedSFolders	145	144	secfso	Inactive	EMSL 1621	Virtual 11T FTICR	2005-02-23 00:00:00
4	11T_FTICR	Finnigan_FTICR	FT_ZippedSFolders	10	88	ftp	Inactive	EMSL 1621	11.5 T FTICR	2000-05-17 00:00:00
22	11T_FTICR_B	BrukerFTMS	FT_ZippedSFolders	106	105	secfso	Inactive	EMSL 1621	11T w/Bruker WS	2004-02-17 00:00:00
36	12T_FTICR	BrukerFTMS	FT_ZippedSFolders	147	247	secfso	Inactive	EMSL 1621	Bruker 12T FTICR magnet	2005-02-24 00:00:00
129	12T_FTICR_Agilent	Agilent_Ion_Trap	Agilent_FTMS	1701	4975	secfso	Active	EMSL 1621	Agilent 12T FTICR magnet. Originally had a Velos Pro front end, but that was later moved to the 21T and this instrument had Exploris01 as its front end. In FY24 the Velos Pro will move back to this instrument and Exploris01 will move to the 21T. This instrument is active so that helium refills can be tracked.  Datasets are uploaded via either the Velos Pro or the Exploris front end.	2015-06-13 06:12:48
65	12T_FTICR_B	BrukerFT_BAF	Bruker_FTMS	1397	4111	secfso	Inactive	EMSL 1621	12T FTICR with updated workstation; set to inactive in May 2022 when the 15T instrument (with MALDI and paracell analyzer) was moved to the 12T magnet due to 15T magnet problems and helium rationing; see 12T_FTICR_P & 12T_FTICR_P_Imaging	2010-07-09 00:00:00
83	12T_FTICR_Imaging	BrukerMALDI_Imaging_V2	MALDI_Imaging	1397	3762	secfso	Inactive	EMSL 1621	12T FTICR with MALDI imaging; was BrukerMALDI_Imaging prior to October 2012; switched to BrukerMALDI_Imaging_V2 with .D folders in 2012; superseded by 12T_FTICR_P_Imaging	2011-05-27 11:16:10
186	12T_FTICR_P	BrukerFT_BAF	Bruker_FTMS	4149	4963	secfso	Active	EMSL 1621	Bruker 12T FTICR with spectrometer from the 15T magnet (the 15T magnet was de-energized in spring 2022 due to magnet helium fill problems and helium shortage)	2022-04-21 15:05:49
187	12T_FTICR_P_Imaging	BrukerMALDI_Imaging_V2	MALDI_Imaging	4149	4964	secfso	Active	EMSL 1621	Bruker 12T FTICR with MALDI imaging capability (mass spectrometer was previously used with the 15T magnet)	2022-04-21 15:08:42
69	15T_FTICR	BrukerFT_BAF	Bruker_FTMS	2710	4134	secfso	Inactive	EMSL 1621	Bruker Solarix 15T with dual ESI\\MALDI source; taken offline in May 2022 due to helium shortage	2010-09-27 11:48:52
190	15T_FTICR_I	BrukerFT_BAF	Bruker_FTMS	4295	4976	secfso	Active	EMSL 1621	Bruker Solarix 15T with an infinity cell	2022-11-02 11:33:18
78	15T_FTICR_Imaging	BrukerMALDI_Imaging_V2	MALDI_Imaging	2710	4135	secfso	Inactive	EMSL 1621	Bruker 15T FTICR with MALDI Imaging datasets; was BrukerMALDI_Imaging prior to October 2012; switched to BrukerMALDI_Imaging_V2 with .D folders in 2012; taken offline in May 2022 due to helium shortage	2011-01-24 11:37:50
106	21T_Agilent	LTQ_FT	21T	1859	4977	secfso	Offline	EMSL 1621	21T Agilent magnet. Prior to March 2024, was coupled to a Velos Pro and thus instrument data was stored as .raw files; for MassIVE, use LTQ Orbitrap Velos Pro, MS:1003096.  Instrument status is Offline since this instrument is used to track helium refills for the 21T.	2013-05-23 16:00:25
166	21T_Booster	FT_Booster_Data	21T	3271	2	secfso	Active	EMSL 1621	Data created by the TI PXIe system connected to the 21T	2019-10-28 17:10:35
6	3T_FTICR	Finnigan_FTICR	Other	12	34	ftp	Inactive	EMSL 1621 (excessed)	3.5 T FTICR	2000-05-17 00:00:00
119	5500XL_SOLiD_Dutch	AB_Sequencer	5500XL_SOLiD	1496	2	fso	Inactive	BSF	Applied Biosciences next gen sequencer (Galya Orr)	2014-05-20 17:18:30
120	5500XL_SOLiD_Milo	AB_Sequencer	5500XL_SOLiD	1496	2	fso	Inactive	BSF	Applied Biosciences next gen sequencer (Galya Orr)	2014-05-20 17:18:46
3	7T_FTICR	Finnigan_FTICR	Other	8	89	secfso	Inactive	EMSL 1621 (excessed)	7 T FTICR	2000-06-20 00:00:00
123	7T_FTICR_B	BrukerFT_BAF	Bruker_FTMS	1502	2426	secfso	Offline	EMSL 1649	7T; not uploading datasets, but still maintaining and entering instrument operation notes; see https://dms2.pnl.gov/instrument_config_history/report/7T	2014-06-20 17:08:16
124	7T_FTICR_B_Imaging	BrukerMALDI_Imaging_V2	MALDI_Imaging	1502	2313	secfso	Inactive	EMSL 1649	7T, imaging	2014-06-20 17:10:12
13	9T_FTICR	BrukerFTMS	FT_ZippedSFolders	46	289	secfso	Inactive	EMSL 1629	9.4T Bruker FTICR	2001-10-22 00:00:00
74	9T_FTICR_B	BrukerFT_BAF	Bruker_FTMS	297	296	secfso	Inactive	EMSL 1621	9T FTICR updated WS	2011-01-03 14:06:37
71	9T_FTICR_Imaging	BrukerMALDI_Imaging	MALDI_Imaging	297	1165	secfso	Inactive	EMSL 1629	Bruker 9T FTICR with MALDI Imaging datasets	2010-11-14 20:20:51
21	9T_FTICR_Q	BrukerFTMS	FT_ZippedSFolders	103	173	fso	Inactive	EMSL 1326	9.4T Bruker w/special quad	2004-01-28 00:00:00
102	AMOLF_VOrbiETD01	LTQ_FT	VelosOrbi	1230	1231	fso	Inactive	AMOLF (Netherlands)	AMOLF Orbitrap data from Ron Heeren	2012-12-03 12:31:26
257	AgGCQTOF02	Agilent_TOF_V2	Agilent_GC_MS	4864	4978	secfso	Active	EMSL 1130	Agilent GC-QTOF, owned by EMSL	2024-07-03 14:52:21
79	AgQTOF03	Agilent_TOF_V2	Agilent_TOF_V2	307	2155	secfso	Inactive	EMSL 1430	Agilent QTOF, WD67695	2011-02-01 16:58:52
70	AgQTOF04	Agilent_TOF_V2	Agilent_TOF_V2	288	1025	fso	Inactive	EMSL 1430	Agilent QTOF	2010-11-04 15:01:20
122	AgQTOF05	Agilent_TOF_V2	Agilent_TOF_V2	1545	3273	secfso	Inactive	EMSL 1401	Agilent QTOF for Metallomics.	2014-05-29 11:20:30
20	AgTOF01	Agilent_TOF	Agilent_TOF	101	124	fso	Inactive	EMSL 1326	Agilent LC/MSD TOF 1	2004-04-06 00:00:00
37	AgTOF02	Agilent_TOF	Agilent_TOF	1063	1188	fso	Inactive	EMSL 1422	Agilent LC/MSD TOF2	2005-05-04 00:00:00
107	AgTOF05	Agilent_TOF_V2	Agilent_TOF_V2	1346	2	secfso	Inactive	EMSL 1430	TOF portion of IMS04_AgTOF05	2013-07-22 10:41:59
189	AgTOF10	Agilent_TOF_V2	Agilent_TOF_V2	4294	4760	secfso	Active	EMSL 1422	G6230BA TOF purchased by instrument development group	2022-10-21 14:27:28
135	Agilent_GC_01	Agilent_Ion_Trap	Agilent_GC	1758	2	secfso	Offline	EMSL 1142	GC with TCD	2015-07-07 16:52:47
59	Agilent_GC_MS_01	Agilent_Ion_Trap	Agilent_GC_MS	2627	4979	secfso	Active	EMSL 1401	Agilent single quadrupole GC-MS for metabolomics. 7890A GC coupled to a 5975C inert XL MSD, with a 7683 series injector (G2614A)	2010-07-30 00:00:00
94	Agilent_GC_MS_02	Agilent_Ion_Trap	Agilent_GC_MS	2628	4980	secfso	Active	EMSL 1401	Agilent single quadrupole GC-MS for metabolomics. 7890A GC coupled to a 5975C inert XL MSD, with a 7693 Autosampler	2012-07-30 13:57:15
181	Agilent_GC_MS_03	Agilent_Ion_Trap	Agilent_GC_MS	3878	4981	secfso	Active	EMSL 1401	Agilent single quadrupole GC-MS for metabolomics. 8890 GC coupled to a 5977 Inert Plus MSD, with a 7693A Autosampler	2021-07-29 17:51:13
96	Agilent_QQQ_04	Agilent_TOF_V2	Agilent_QQQ	1184	4982	secfso	Active	EMSL 1521	Agilent 6490 Triple Quad LC/MS	2012-08-22 15:32:19
141	Agilent_RTHDMS	Agilent_Ion_Trap	Other	2	2	secfso	Inactive	EMSL 1648	Real-Time High Definition Mass Spectrometry.  Saves data to .D folders	2016-05-25 20:59:39
17	Agilent_SL1	Agilent_Ion_Trap	Agilent_Ion_Trap	94	123	fso	Inactive	EMSL 1422 (excessed)	Agilent 1100 SL 1	2003-11-11 00:00:00
19	Agilent_XCT1	Agilent_Ion_Trap	Agilent_Ion_Trap	99	125	fso	Inactive	EMSL 1422	Agilent 1100 LC/MSD XCT 1	2004-03-30 00:00:00
236	Alder	LCMSNet_LC	LCMSNet_LC	4587	4930	secfso	Active	EMSL 1621	LCMSNet LC with a Shimadzu LC40D infusion pump. Used for LCDatasetCapture tasks.  The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets.	2023-11-06 11:15:20
147	Altis01	Triple_Quad	TSQ	2545	4968	secfso	Active	EMSL 1142	Thermo Altis triple quad, MS:1002874	2017-09-28 10:40:11
151	Altis02	Triple_Quad	TSQ	2791	4983	secfso	Active	EMSL 1142	Thermo Altis triple quad, MS:1002874	2018-04-17 11:33:50
167	Altis03	Triple_Quad	TSQ	3275	4967	secfso	Active	EMSL 1142	Thermo Altis triple quad, MS:1002874	2019-11-18 16:27:17
247	Altis04	Triple_Quad	TSQ	4828	4984	secfso	Active	EMSL 1142	Thermo Altis Plus triple quad, MS:1003292	2024-04-16 16:59:57
234	Aragorn	Waters_Acquity_LC	Waters_Acquity_LC	4585	4928	secfso	Active	EMSL 1142	Waters nanoAcquity LC	2023-11-03 13:15:38
225	Arwen	Waters_Acquity_LC	Waters_Acquity_LC	4576	4919	secfso	Active	EMSL 1314	Waters Acquity M-Class LC	2023-11-02 17:25:10
192	Ascend01	LTQ_FT	Ascend	4440	4951	secfso	Active	BSF 1229	Purchased by Leidos	2023-04-18 12:19:15
254	Astral01	LTQ_FT	Astral	4839	4961	secfso	Active	BSF 2235	Thermo Astral instrument, 50% BSD, 50% NSD	2024-05-28 18:03:42
131	BSF_GC01	Agilent_Ion_Trap	Agilent_GC	1754	2	secfso	Offline	BSF 1229	GC with FID	2015-07-06 16:23:30
139	BSF_GC02	Agilent_Ion_Trap	Agilent_GC	1991	2	secfso	Offline	BSF 1215	GC with FID	2016-01-27 11:33:06
132	BSF_GCMS01	Agilent_Ion_Trap	Agilent_GC_MS	1755	2	secfso	Offline	BSF 1229	GC-MS	2015-07-06 16:24:23
133	BSF_GCMS02	Agilent_Ion_Trap	Agilent_GC_MS	1756	2	secfso	Offline	BSF 1229	GC-MS	2015-07-06 16:24:34
134	BSF_GCMS03	Agilent_Ion_Trap	Agilent_GC_MS	1757	2	secfso	Offline	BSF 1229	GC-MS	2015-07-06 16:24:45
226	Balzac	Waters_Acquity_LC	Waters_Acquity_LC	4577	4920	secfso	Active	EMSL 1142	Waters Acquity M-Class LC	2023-11-02 17:25:42
218	Bane	Waters_Acquity_LC	Waters_Acquity_LC	4569	4912	secfso	Active	EMSL 1444	Waters nanoAcquity LC	2023-11-02 17:19:40
249	Barney	Thermo_SII_LC	Thermo_SII_LC	4830	4938	secfso	Active	EMSL 1142	Vanquish Neo LC (binary pump and autosampler). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Purchased by same project as Exploris03, not EMSL owned	2024-04-16 17:03:48
216	Bart	Thermo_SII_LC	Thermo_SII_LC	4567	4910	secfso	Active	BSF 1229	Vanquish Neo LC (binary pump, autosampler, and column compartment)	2023-11-01 10:16:39
230	Bilbo	Waters_Acquity_LC	Waters_Acquity_LC	4581	4924	secfso	Active	EMSL 1526	Waters nanoAcquity LC	2023-11-03 10:17:43
204	Birch	Thermo_SII_LC	Thermo_SII_LC	4555	4898	secfso	Active	BSF 1229	LCMSNet LC with Thermo RSLCnano NCS-3500RS nano/loading pump	2023-10-26 14:41:17
232	Brandi	Waters_Acquity_LC	Waters_Acquity_LC	4583	4926	secfso	Active	EMSL 1444	Waters Acquity H-Class LC	2023-11-03 10:18:37
184	Broad_Exploris01	LTQ_FT	Exploris	3987	3989	fso	Active	MIT - Broad (Massachusetts)	Broad Institute Exploris, MS:1003029	2021-10-22 09:24:08
50	Broad_Orb1	LTQ_FT	Orbitrap	218	1011	fso	Inactive	MIT - Broad (Massachusetts)	Broad Institute LTQ-Orbitrap	2006-10-09 00:00:00
168	Broad_QEHFX01	LTQ_FT	QEHFX	3277	3596	fso	Active	MIT - Broad (Massachusetts)	Broad Institute Q Exactive HF-X, MS:1002877	2019-11-21 16:22:22
148	Broad_QExactP01	LTQ_FT	QExactive	2625	2711	fso	Inactive	MIT - Broad (Massachusetts)	Broad Institute Q Exactive Plus Orbitrap	2017-12-05 11:53:30
87	Broad_VOrbiETD01	LTQ_FT	VelosOrbi	1891	3597	fso	Inactive	MIT - Broad (Massachusetts)	Broad Institute LTQ-Velos Orbitrap, Q Exactive, and Lumos data.  Q Exactive Plus data is tracked with instrument Broad_QExactP01	2012-01-13 14:31:13
66	BrukerTOF_01	BrukerMALDI_Spot	MALDI_TOF	295	1091	secfso	Inactive	EMSL 1621	Bruker Ultraflextreme MALDI TOFTOF	2010-08-02 00:00:00
73	BrukerTOF_Imaging_01	BrukerMALDI_Imaging	MALDI_Imaging	295	294	secfso	Inactive	EMSL 1621	Bruker TOF with MALDI imaging	2010-11-17 14:56:17
88	Bruker_FT_IonTrap01	Bruker_Amazon_Ion_Trap	Bruker_Amazon_Ion_Trap	1088	1090	fso	Inactive	EMSL 1553	Instrument to track FT/Ion trap data from Bruker	2012-01-31 11:33:18
112	CBSS_Orb1	LTQ_FT	Orbitrap	1391	1941	fso	Inactive	331 Building	Chemical and Biological Signature Sciences	2013-11-05 11:49:32
210	Cato	Thermo_SII_LC	Thermo_SII_LC	4561	4904	secfso	Active	EMSL 1401	Thermo RSLCnano Autosampler and pump	2023-11-01 10:12:52
211	Cicero	Thermo_SII_LC	Thermo_SII_LC	4562	4905	secfso	Active	EMSL 1526	Thermo RSLCnano Autosampler and pump	2023-11-01 10:13:08
200	Crater	Thermo_SII_LC	Thermo_SII_LC	4551	4894	secfso	Active	EMSL 1444	Vanquish Flex LC for lipids and metabolomics (2 binary pumps, autosampler, 2 column compartments, and charged aerosol detector)	2023-10-25 20:19:53
86	DMS_Pipeline_Data	Data_Folders	DataFolders	2	1079	fso	Inactive	In-silico	Used for placeholder datasets created for DMS_Pipeline DB jobs	2012-01-09 19:43:00
253	Dragonfly	Thermo_SII_LC	Thermo_SII_LC	4838	4942	secfso	Active	BSF 2235	NanoPOTS with Vanquish Neo Binary Pump. Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Not EMSL owned	2024-05-21 20:18:19
199	EMSL-NMR-LC	PrepHPLC	PrepHPLC	4502	4893	secfso	Active	EMSL 1430	EMSL-NMR-LC, or Tonga; for uploading occasional files with DAD data	2023-09-22 10:23:35
171	Eclipse01	LTQ_FT	Eclipse	3525	4959	secfso	Active	EMSL 1444	Orbitrap Eclipse Tribrid, MS:1003029	2020-09-04 17:54:11
178	Eclipse02	LTQ_FT	Eclipse	3789	4985	secfso	Active	EMSL 1526	Orbitrap Eclipse Tribrid - CPTAC loan, MS:1003029	2021-04-29 14:55:13
205	Elm	Thermo_SII_LC	Thermo_SII_LC	4556	4899	secfso	Active	EMSL 1444	LCMSNet LC with Thermo RSLCnano NCS-3200RS nano/loading pump	2023-11-01 10:09:23
150	Emory_Lumos01	LTQ_FT	Lumos	2680	2681	fso	Inactive	Emory (Atlanta, GA)	Emory School of Medicine Orbitrap Fusion Lumos	2018-01-15 15:46:16
54	Exact01	Thermo_Exactive	Exactive	244	1306	secfso	Inactive	EMSL 1621	Fast scanning high resolution mass spectrometer	2009-04-22 00:00:00
55	Exact02	Thermo_Exactive	Exactive	250	249	secfso	Inactive	EMSL 1526	Fast scanning high resolution mass spectrometer	2009-06-01 00:00:00
57	Exact03	Thermo_Exactive	Exactive	255	2848	secfso	Inactive	EMSL 1526	Fast scanning high resolution mass spectrometer	2009-06-24 00:00:00
82	Exact04	Thermo_Exactive	Exactive	314	3062	secfso	Inactive	EMSL 1426	Coupled to IMS06 in 2016, Given to BYU	2011-03-18 10:40:45
173	Exploris01	LTQ_FT	21T	3535	4971	secfso	Active	EMSL 1621	Thermo Exploris 480. Prior to March 2024, Exloris01 was coupled with an Agilent 12T magnet. In March 2024, it was coupled with the Agilent 21T, replacing an Orbitrap Velos Pro.	2020-09-18 00:25:51
193	Exploris02	LTQ_FT	Exploris	4441	4957	secfso	Active	BSF 1229	Orbitrap Exploris 240, MS:1003094	2023-04-18 12:19:29
197	Exploris03	LTQ_FT	Exploris	4496	4952	secfso	Active	BSF 1229	Orbitrap Exploris 480, MS:1003028	2023-07-27 16:14:06
239	Exploris04	LTQ_FT	Exploris	4631	4974	secfso	Active	BSF 1229	Orbitrap Exploris 480, MS:1003028	2023-11-28 15:37:15
242	Exploris05	LTQ_FT	Exploris	4657	4953	secfso	Active	BSF 1229	Katrina's PPI (Predictive Phenomics Initiative) instrument; Orbitrap Exploris 480, MS:1003028	2024-01-09 14:29:09
246	Exploris06	LTQ_FT	Exploris	4733	4958	secfso	Active	EMSL 1526	Orbitrap Exploris 480 purchased by EMSL; MS:1003028,	2024-03-01 11:00:40
259	Exploris07	LTQ_FT	Exploris	4948	4965	secfso	Active	BSF 1215	Vlad's Alzheimer projects instrument; Orbitrap Exploris 480, MS:1003028	2024-08-15 11:09:11.441472
258	ExplorisMX01	LTQ_FT	Exploris	4865	4986	secfso	Active	EMSL 1130	Orbitrap Exploris MX, owned by EMSL	2024-07-03 15:00:57
175	External_Agilent_QQQ	Agilent_TOF_V2	Agilent_QQQ	3709	3714	fso	Active	Offsite	Agilent triple-quad data acquired offsite	2021-01-19 20:47:37
185	External_Agilent_QTOF	Agilent_TOF_V2	Agilent_TOF_V2	4073	4079	fso	Active	Offsite	Agilent Q-TOF data acquired offsite	2022-02-25 08:31:43
195	External_Ascend	LTQ_FT	Ascend	4491	4493	fso	Active	Offsite	Data acquired offsite using a Thermo Ascend mass spec	2023-07-18 12:50:05
244	External_Astral	LTQ_FT	Astral	4726	4727	fso	Active	Offsite	Thermo TOF/Orbitrap tribrid	2024-02-05 11:21:14
164	External_Bruker_timsTOF	BrukerTOF_TDF	timsTOF	3098	3126	fso	Active	Offsite	Data acquired at Bruker	2019-06-11 14:52:16
176	External_Eclipse	LTQ_FT	Eclipse	3710	4868	fso	Active	Offsite	Orbitrap Eclipse data acquired outside PNNL	2021-01-26 17:09:47
179	External_Exploris	LTQ_FT	Exploris	3791	4827	fso	Active	Offsite	Data acquired offsite using a Thermo Exploris mass spec	2021-05-05 15:31:49
188	External_IMS_AgQTOF	IMS_Agilent_TOF_DotD	IMS	4152	2	fso	Active	Offsite	IMS .d datasets acquired offsite	2022-05-20 09:15:09
144	External_Illumina	Illumina_Sequencer	Illumina	2238	2240	fso	Inactive	0	RNA sequence data collected onsite or offsite	2016-11-18 15:38:55
67	External_LTQ	Finnigan_Ion_Trap	LTQ	2539	2538	fso	Inactive	Offsite	LTQ data acquired outside PNNL	2010-08-16 00:00:00
196	External_Lumos	LTQ_FT	Lumos	4492	4494	fso	Active	Offsite	Data acquired offsite using a Thermo Lumos mass spec	2023-07-18 12:51:28
68	External_Orbitrap	LTQ_FT	VelosOrbi	1141	4950	fso	Active	Offsite	Orbitrap data acquired outside PNNL	2010-08-31 16:55:06
177	External_Orbitrap_Fusion	LTQ_FT	VelosOrbi	3712	4031	fso	Active	Offsite	Orbitrap Fusion Lumos data acquired outside PNNL, MS:1002732	2021-01-28 10:35:08
170	External_QEHFX	LTQ_FT	QEHFX	3355	3358	fso	Active	Offsite	Q Exactive HF-X data acquired outside PNNL, MS:1002877	2020-02-07 15:10:04
116	External_QExactive	LTQ_FT	QExactive	1704	4153	fso	Active	Offsite	QExactive data acquired outside PNNL	2014-04-03 11:04:00
161	External_Thermo_FAIMS	LTQ_FT	Lumos	3047	3360	fso	Inactive	Thermo (San Jose, CA)	External Thermo Lumos with a FAIMS source	2019-04-15 11:09:32
113	External_Waters_TOF	Waters_TOF	Waters_TOF	1392	1395	fso	Inactive	Offsite	Waters QTof data (LC-MS or LC-MSn)	2013-11-05 15:58:32
42	FHCRC_LTQ1	Finnigan_Ion_Trap	LTQ	167	166	fso	Inactive	FHCRC (Seattle, WA)	Fred Hutchinson Cancer Research Center Data	2005-11-17 00:00:00
64	FHCRC_Orb1	LTQ_FT	Orbitrap	1142	276	fso	Inactive	FHCRC (Seattle, WA)	Fred Hutchinson Cancer Research Center Data	2010-06-09 00:00:00
237	Fir	LCMSNet_LC	LCMSNet_LC	4588	4931	secfso	Active	EMSL 1621	LCMSNet LC with a Shimadzu LC40D infusion pump. Used for LCDatasetCapture tasks.  The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets.	2023-11-06 11:15:33
219	Frodo	Waters_Acquity_LC	Waters_Acquity_LC	4570	4913	secfso	Active	EMSL 1401	Waters nanoAcquity LC	2023-11-02 17:20:59
136	GCQE01	GC_QExactive	GC_QExactive	1889	4987	secfso	Active	EMSL 1401	GC QExactive: Thermo Trace 1310 GC with a QExactive detector; for MassIVE use Q Exactive GC Orbitrap, MS:1003395	2015-10-20 14:37:03
220	Gandalf	Waters_Acquity_LC	Waters_Acquity_LC	4571	4914	secfso	Active	EMSL 1401	Waters nanoAcquity LC	2023-11-02 17:21:33
213	Glacier	Thermo_SII_LC	Thermo_SII_LC	4564	4907	secfso	Active	EMSL 1521	Vanquish LC for high-flow (binary pump, autosampler, and column compartment)	2023-11-01 10:15:10
202	Holly	Thermo_SII_LC	Thermo_SII_LC	4553	4896	secfso	Active	EMSL 1526	LCMSNet LC with Thermo RSLCnano NCS-3500RS nano/loading pump	2023-10-26 14:37:36
240	Homer	Thermo_SII_LC	Thermo_SII_LC	4632	4933	secfso	Active	BSF 1229	Vanquish Neo LC (binary pump, autosampler, and column compartment). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets.	2023-12-01 16:47:28
47	IMS02_AgTOF06	IMS_Agilent_TOF_UIMF	IMS	204	1337	secfso	Inactive	EMSL 1429	Deactivated 8/1/2013 since now part of IMS07_AgTOF06	2009-04-15 00:00:00
46	IMS03_AgQTOF01	IMS_Agilent_TOF_UIMF	IMS	202	3161	secfso	Inactive	EMSL 1430	IMS Agilent TOF, WD59518	2009-04-10 00:00:00
77	IMS04_AgTOF05	IMS_Agilent_TOF_UIMF	IMS	303	3860	secfso	Inactive	EMSL 1430	IMS Agilent TOF, WD80257	2011-01-20 17:11:55
111	IMS05_AgQTOF03	IMS_Agilent_TOF_UIMF	IMS	1357	4389	secfso	Inactive	EMSL 1426	WE17561 for IMS05; WD59467 for AgQTOF03, IMS cart has been removed as of October 2022, and is not going back in front of the QTOF.	2013-09-03 14:40:23
80	IMS05_AgQTOF04	IMS_Agilent_TOF_UIMF	IMS	1093	1308	secfso	Inactive	EMSL 1426	Deactivated 9/3/2013 since replaced with IMS05_AgQTOF03	2011-03-18 10:06:52
81	IMS06_AgTOF07	IMS_Agilent_TOF_UIMF	IMS	312	2852	secfso	Inactive	EMSL 1426	IMS Agilent TOF, WD59466 for TOF07	2011-03-18 10:10:14
118	IMS07_AgTOF04	IMS_Agilent_TOF_UIMF	IMS	1494	3870	secfso	Inactive	EMSL 1430	Excessed in 2020: IMS with 20,000 m/z upper limit; WD56206 for TOF04	2014-05-02 15:13:29
108	IMS07_AgTOF06	IMS_Agilent_TOF_UIMF	IMS	1348	1540	secfso	Inactive	EMSL 1430	Deactivated 4/7/2014 since AgTOF06 is now on SLIM03	2013-08-01 16:14:31
109	IMS08_AgQTOF05	IMS_Agilent_TOF_DotD	IMS	1353	4988	secfso	Active	EMSL 1521	First generation IMS from Agilent; PT27418 for AgQTOF05	2013-08-21 17:35:26
140	IMS09_AgQToF06	IMS_Agilent_TOF_DotD	IMS	2066	4989	secfso	Active	EMSL 1521	Second IMS from Agilent; property tag WD56541	2016-05-09 14:21:26
165	IMS10_AgQTOF07	IMS_Agilent_TOF_DotD	IMS	3184	2	secfso	Active	EMSL 1526	Agilent 6560;  property tag PT27672	2019-07-24 11:27:40
172	IMS11_AgQTOF08	IMS_Agilent_TOF_DotD	IMS	3526	4548	secfso	Inactive	EMSL 1430	Agilent 6560B IM-QTOF; replaced under warranty. Powered down, packaged, and shipped back to Agilent by Agilent technicians as of February 23rd, 2023. Warranty replacement instrument is IMS12-AgQTOF09	2020-09-04 18:01:52
191	IMS12-AgQTOF09	IMS_Agilent_TOF_DotD	IMS	4399	4990	secfso	Active	EMSL 1430	Agilent 6560C IM-QTOF; warranty replacement for IMS11_AgQTOF08	2023-03-02 14:43:27
45	IMS_TOF_1	IMS_Agilent_TOF_UIMF	IMS	200	199	secfso	Inactive	EMSL 1430	IMS AGILENT TOF	2009-04-01 00:00:00
114	JCVI_VPro01	LTQ_FT	VelosPro	1394	1471	fso	Inactive	JCVI (Rockville, MD)	J. Craig Venter Institute Velos Pro	2013-11-22 12:43:41
149	JHU_QExactP01	LTQ_FT	QExactive	2629	2630	fso	Inactive	JHU (Baltimore)	Johns Hopkins University Q Exactive Orbitrap	2017-12-15 14:02:55
91	JHU_VOrbiETD01	LTQ_FT	VelosOrbi	1136	2631	fso	Inactive	JHU (Baltimore)	Johns Hopkins University LTQ-Velos Orbitrap and Orbitrap Lumos	2012-06-05 21:16:51
2	LCQ_C1	Finnigan_Ion_Trap	LCQ	6	126	secfso	Inactive	EMSL 1326 (not conneted to network)	LCQ-C1	2000-05-15 00:00:00
1	LCQ_C2	Finnigan_Ion_Trap	LCQ	4	127	secfso	Inactive	EMSL 1526	LCQ-C2	2001-03-12 00:00:00
15	LCQ_C3	Finnigan_Ion_Trap	LCQ	56	128	fso	Inactive	331 Building	LCQ_CLASSIC_3	2002-03-08 00:00:00
9	LCQ_D1	Finnigan_Ion_Trap	LCQ	37	130	secfso	Inactive	EMSL 1326	LCQ-DUO1	2001-02-22 00:00:00
10	LCQ_D2	Finnigan_Ion_Trap	LCQ	40	131	secfso	Inactive	EMSL 1526 (in hallway)	LCQ-DUO2	2001-05-02 00:00:00
31	LCQ_JA_GTL	Finnigan_Ion_Trap	LCQ	137	136	fso	Inactive	EMSL 2588	Virtual Instrument for GTL_Core	2004-09-27 00:00:00
12	LCQ_XP1	Finnigan_Ion_Trap	LCQ	44	132	secfso	Inactive	BSF 1213	LCQ_DECA_XP1	2001-10-17 00:00:00
14	LCQ_XP2	Finnigan_Ion_Trap	LCQ	51	133	secfso	Inactive	BSF 1213 (not conneted to network)	LCQ_DECA_XP2	2002-01-14 00:00:00
23	LTQ_1	Finnigan_Ion_Trap	LTQ	108	400	secfso	Inactive	EMSL 1617	Finnigan LTQ #1; broken since April 2011	2004-06-19 00:00:00
33	LTQ_2	Finnigan_Ion_Trap	LTQ	141	3049	secfso	Inactive	EMSL 1526	Finnigan LTQ #2	2004-11-08 00:00:00
34	LTQ_3	Finnigan_Ion_Trap	LTQ_Prep	143	2840	secfso	Inactive	BSF 1208	Finnigan LTQ #3	2004-11-22 00:00:00
39	LTQ_4	Finnigan_Ion_Trap	LTQ	156	3855	secfso	Inactive	EMSL 1526	Finnigan LTQ #4	2005-05-27 00:00:00
52	LTQ_ETD_1	Finnigan_Ion_Trap	LTQ_ETD	221	3055	secfso	Inactive	EMSL 1444	LTQ XL, Given to another group	2007-11-15 00:00:00
38	LTQ_FB1	Finnigan_Ion_Trap	LTQ	153	1247	secfso	Inactive	PSL 522	Agilent LC/Thermo LTQ (Fungal)	2005-04-28 00:00:00
32	LTQ_FT1	LTQ_FT	LTQ_FT	139	1054	secfso	Inactive	EMSL 1617	LTQ-FT 1 (LTQ3QFVL41)	2004-10-22 00:00:00
44	LTQ_Orb_1	LTQ_FT	Orbitrap	171	3051	secfso	Inactive	EMSL 1444	LTQ with an LTQ Orbitrap	2006-01-06 00:00:00
48	LTQ_Orb_2	LTQ_FT	Orbitrap	206	3053	secfso	Inactive	EMSL 1444	LTQ with an LTQ Orbitrap, Returned to Thermo	2006-10-23 00:00:00
51	LTQ_Orb_3	LTQ_FT	Orbitrap	3846	4131	fso	Offline	EMSL 1444	LTQ XL with an LTQ Orbitrap, Returned to Thermo	2007-07-26 00:00:00
146	LTQ_Orb_4	LTQ_FT	Orbitrap	2373	2994	fso	Inactive	EMSL 1429	LTQ XL with an LTQ Orbitrap	2017-04-11 15:22:21
43	LTQ_RITE	Finnigan_Ion_Trap	LTQ	169	168	fso	Inactive	n/a	Virtual instrument for relocated RITE data	2005-12-01 00:00:00
207	Larch	Thermo_SII_LC	Thermo_SII_LC	4558	4901	secfso	Active	EMSL 1422	LCMSNet LC with Thermo RSLCnano NCS-3200RS nano/loading pump	2023-11-01 10:10:06
217	Lisa	Thermo_SII_LC	Thermo_SII_LC	4568	4911	secfso	Active	BSF 1229	Vanquish Neo LC (binary pump, autosampler, and column compartment)	2023-11-01 10:16:58
229	Lola	Waters_Acquity_LC	Waters_Acquity_LC	4580	4923	secfso	Active	EMSL 1521	Waters Acquity H-Class LC	2023-11-02 17:27:37
138	Lumos01	LTQ_FT	Lumos	1901	4973	secfso	Active	EMSL 1526	Orbitrap Fusion Lumos, MS:1002732	2015-12-15 16:13:14
145	Lumos02	LTQ_FT	Lumos	2318	4969	secfso	Active	BSF 1217	Orbitrap Fusion Lumos, MS:1002732	2017-03-22 15:11:53
160	Lumos03	LTQ_FT	Lumos	2998	4970	secfso	Active	EMSL 1444	Orbitrap Fusion Lumos, MS:1002732	2019-01-16 16:30:45
92	MIT_Orbi01	LTQ_FT	VelosOrbi	1137	1139	fso	Inactive	MIT - Forest White lab (Massachusets)	MIT Orbitrap Elite or Orbitrap XL	2012-06-05 21:28:14
238	Magnolia	LCMSNet_LC	LCMSNet_LC	4589	4932	secfso	Active	EMSL 1621	LCMSNet LC with a Shimadzu LC40D infusion pump. Used for LCDatasetCapture tasks.  The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets.	2023-11-06 11:15:48
201	Maple	Thermo_SII_LC	Thermo_SII_LC	4552	4895	secfso	Active	EMSL 1444	LCMSNet LC with Thermo RSLCnano NCS-3500RS nano/loading pump	2023-10-26 14:37:17
243	Marge	Thermo_SII_LC	Thermo_SII_LC	4725	4934	secfso	Active	BSF 1229	Vanquish Neo LC (binary pump, autosampler, and column compartment). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Purchased with Exploris05, Katrina's PPI (Predictive Phenomics Initiative)	2024-01-16 10:04:23
75	Maxis_01	BrukerTOF_BAF	Bruker_QTOF	299	2850	secfso	Inactive	EMSL 1142	Bruker Maxis qTof for Imaging (MALDI)	2011-01-06 13:45:54
221	Merry	Waters_Acquity_LC	Waters_Acquity_LC	4572	4915	secfso	Active	EMSL 1526	Waters nanoAcquity LC	2023-11-02 17:22:12
248	Moe	Thermo_SII_LC	Thermo_SII_LC	4829	4937	secfso	Active	EMSL 1142	Vanquish Neo LC (binary pump and autosampler). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Purchased with Altis04, not EMSL owned	2024-04-16 17:03:03
252	Monty	Thermo_SII_LC	Thermo_SII_LC	4837	4941	secfso	Active	BSF 2235	Vanquish Neo LC (binary pump and autosampler). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Not EMSL owned	2024-05-21 20:17:11
137	NU_QExactive	LTQ_FT	Other	1892	1893	fso	Inactive	Northwestern University - Kelleher lab	For instrument data shared under the CPTAC project	2015-11-05 11:00:55
245	Ned	Thermo_SII_LC	Thermo_SII_LC	4732	4935	secfso	Active	EMSL 1526	Vanquish Neo LC (binary pump and autosampler). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Purchased with Exploris06, EMSL owned	2024-03-01 10:58:45
206	Oak	Thermo_SII_LC	Thermo_SII_LC	4557	4900	secfso	Active	EMSL 1526	LCMSNet LC with Thermo RSLCnano NCS-3200RS nano/loading pump	2023-11-01 10:09:47
203	Olympic	Thermo_SII_LC	Thermo_SII_LC	4554	4897	secfso	Active	EMSL 1526	Vanquish Flex LC for metabolomics (binary pump, autosampler, and 2 column compartments)	2023-10-26 14:39:31
63	Orbi_FB1	LTQ_FT	Orbitrap	267	2072	secfso	Inactive	331 Building, Rm 315	OBP sponsored Fungal Biotech Workstation	2010-05-01 00:00:00
250	Patty	Thermo_SII_LC	Thermo_SII_LC	4835	4939	secfso	Active	EMSL 1444	Vanquish Neo LC (binary pump and autosampler). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Not EMSL owned	2024-05-21 20:10:05
222	Pippin	Waters_Acquity_LC	Waters_Acquity_LC	4573	4916	secfso	Active	BSF 1217	Waters nanoAcquity LC	2023-11-02 17:22:48
227	Precious	Waters_Acquity_LC	Waters_Acquity_LC	4578	4921	secfso	Active	EMSL 1142	Waters Acquity M-Class LC	2023-11-02 17:26:15
97	PrepHPLC1	PrepHPLC	PrepHPLC	1189	1211	secfso	PrepHPLC	BSF 1208	Used for entering operation and maintenance notes, plus also for Prep LC runs (no datasets)	2012-09-21 13:33:42
98	PrepHPLC2	PrepHPLC	PrepHPLC	1190	2	secfso	PrepHPLC	BSF 1208	Used for entering operation and maintenance notes, plus also for Prep LC runs (no datasets)	2012-09-21 13:33:56
99	PrepHPLC3	PrepHPLC	PrepHPLC	1191	2	secfso	Inactive	BSF	Used for entering operation and maintenance notes, plus also for Prep LC runs (no datasets)	2012-09-21 13:34:09
100	PrepHPLC4	PrepHPLC	PrepHPLC	1192	2	secfso	Inactive	BSF 1215	Used for entering operation and maintenance notes, plus also for Prep LC runs (no datasets)	2012-09-21 13:34:20
101	PrepHPLC5	PrepHPLC	PrepHPLC	1193	2	secfso	PrepHPLC	BSF 2240	Used for entering operation and maintenance notes, plus also for Prep LC runs (no datasets)	2012-09-21 13:34:32
153	PrepHPLC6	PrepHPLC	PrepHPLC	2869	2	secfso	PrepHPLC	BSF 1206	Used for entering operation and maintenance notes, plus also for Prep LC runs (no datasets)	2018-07-31 15:14:01
154	PrepHPLC7	PrepHPLC	PrepHPLC	2896	2	secfso	PrepHPLC	BSF 2240	Used for entering operation and maintenance notes, plus also for Prep LC runs (no datasets)	2018-10-03 15:52:27
241	PrepHPLC8	PrepHPLC	PrepHPLC	4646	2	secfso	Active	BSF 2240	Thermo Vanquish Flex Autosampler/Fraction Collector, controlled with Chromeleon software	2024-01-02 11:41:48
27	QC_Ag_TOF	Agilent_TOF	Agilent_TOF	116	188	fso	Inactive	EMSL 1553	Agilent TOF-type instrument for QC Process	2005-05-11 00:00:00
26	QC_Ag_XCT	Agilent_Ion_Trap	Agilent_Ion_Trap	114	113	fso	Inactive	EMSL 1553	Agilent XCT-type instrument for QC Process	2005-05-01 00:00:00
25	QC_Bruker_ICR	BrukerFTMS	Other	112	175	fso	Inactive	EMSL 1553	Bruker-type instrument for QC Process	2004-07-30 00:00:00
30	QC_Fin_ICR	Finnigan_FTICR	Other	122	121	fso	Inactive	EMSL 1553	Finnigan FTICR-type instrument for QC Process	2006-12-13 00:00:00
24	QC_LCQ	Finnigan_Ion_Trap	LCQ	110	189	fso	Inactive	EMSL 1553	LCQ-type instrument for QC Process	2004-07-29 00:00:00
29	QC_LTQ	Finnigan_Ion_Trap	LTQ	120	190	fso	Inactive	EMSL 1553	LTQ-type instrument for QC Process	2004-10-15 00:00:00
40	QC_LTQ_FT	LTQ_FT	LTQ_FT	158	191	fso	Inactive	EMSL 1553	QC Process LTQ_FT	2005-06-28 00:00:00
41	QC_LTQ_Orbitrap	LTQ_FT	Orbitrap	165	192	fso	Inactive	EMSL 1553	Orbitrap Test Data	2005-07-22 00:00:00
28	QC_MM_TOF	Waters_TOF	Waters_TOF	118	117	fso	Inactive	EMSL 1553	Micromass TOF-type instrument for QC Process	2006-11-08 00:00:00
158	QEHFX01	LTQ_FT	QEHFX	2996	4960	secfso	Active	EMSL 1444	Q Exactive HF-X, MS:1002877	2019-01-16 16:21:27
159	QEHFX02	LTQ_FT	QEHFX	2997	4954	secfso	Active	EMSL 1444	Q Exactive HF-X, MS:1002877	2019-01-16 16:21:38
169	QEHFX03	LTQ_FT	QEHFX	3318	4956	secfso	Active	EMSL 1444	Q Exactive HF-X, MS:1002877	2020-01-14 15:05:55
103	QExact01	LTQ_FT	QExactive	1232	2859	secfso	Inactive	EMSL 1526	Q-Exactive 1	2012-12-07 14:32:20
127	QExactHF03	LTQ_FT	QExactive	1633	4972	secfso	Active	EMSL 1526	Q Exactive HF, MS:1002523\t	2015-02-19 10:12:31
130	QExactHF05	LTQ_FT	QExactive	1706	4991	secfso	Active	EMSL 1621	Q Exactive HF, MS:1002523. Has HMR/UHMR configuration (boards swapped). Supports MALDI (Spectroglyph), UVPD, and ECD/ETD, depending on the connected hardware. While the MALDI source is attached, use instrument QExactHF05_Imaging for new datasets.	2015-06-29 10:54:50
180	QExactHF05_Imaging	LTQ_FT	QExactive_Imaging	1706	4947	secfso	Active	EMSL 1621	Q Exactive HF, MS:1002523. Has HMR/UHMR configuration (boards swapped). Supports MALDI (Spectroglyph), UVPD, and ECD/ETD, depending on the connected hardware. When the MALDI source is attached, use instrument QExactHF05_Imaging for new datasets.	2021-06-24 16:09:22
121	QExactP02	LTQ_FT	QExactive	1497	4966	secfso	Active	EMSL 1526	Q Exactive Plus, MS:1002634	2014-05-29 11:08:29
128	QExactP04	LTQ_FT	QExactive	1662	4955	secfso	Active	EMSL 1444	Q Exactive Plus, MS:1002634	2015-04-08 14:47:10
143	QExactP06	LTQ_FT	QExactive	2226	4992	secfso	Active	EMSL 1426	Q Exactive Plus, MS:1002634. WD56888	2016-10-19 13:33:16
11	QTOF_1322	QStar_QTOF	Other	42	134	fso	Inactive	EMSL 1426	QTOF-1322	2001-07-27 00:00:00
18	QTOF_MM1	Waters_TOF	Waters_TOF	96	135	secfso	Inactive	EMSL 1526	Micromass QTOF 1	2004-03-08 00:00:00
76	QTrap01	Sciex_QTrap	QTrap	301	1528	secfso	Inactive	EMSL 1444	ABI Sciex Qtrap 5500 for MRM-based experiments	2011-01-13 16:01:03
228	Rage	Waters_Acquity_LC	Waters_Acquity_LC	4579	4922	secfso	Active	EMSL 1142	Waters Acquity M-Class LC	2023-11-02 17:26:37
214	Rainier	Thermo_SII_LC	Thermo_SII_LC	4565	4908	secfso	Active	EMSL 1521	Vanquish LC for high-flow (binary pump, autosampler, and column compartment)	2023-11-01 10:15:33
208	Remus	Thermo_SII_LC	Thermo_SII_LC	4559	4902	secfso	Active	EMSL 1444	Thermo RSLCnano Autosampler and pump	2023-11-01 10:12:06
209	Romulus	Thermo_SII_LC	Thermo_SII_LC	4560	4903	secfso	Active	EMSL 1444	Thermo RSLCnano Autosampler and pump	2023-11-01 10:12:26
233	Roxanne	Waters_Acquity_LC	Waters_Acquity_LC	4584	4927	secfso	Active	EMSL 1142	Waters Acquity H-Class LC	2023-11-03 10:18:56
110	SLIM01_AgQTOF04	IMS_Agilent_TOF_UIMF	SLIM	1356	3867	secfso	Inactive	EMSL 1430	IMS with SLIM; WD59488 for AgQTof04	2013-08-28 13:54:08
95	SLIM02_AgQTOF02	IMS_Agilent_TOF_UIMF	SLIM	1183	4995	secfso	Inactive	EMSL 1422	IMS with SLIM; WD41434 for AgQTOF02 (serial US42300267)	2012-08-21 09:51:34
162	SLIM03_AgQTOF01	IMS_Agilent_TOF_UIMF	SLIM	3089	2	secfso	Active	EMSL 1526	IMS with SLIM	2019-05-03 19:30:45
152	SLIM03_AgQTOF04	IMS_Agilent_TOF_UIMF	SLIM	2999	3002	fso	Inactive	EMSL 1526	IMS with SLIM	2018-05-15 11:00:50
117	SLIM03_AgTOF06	IMS_Agilent_TOF_UIMF	SLIM	1467	3869	secfso	Inactive	EMSL 1526	IMS with SLIM; AgTOF06 has property tag WD59466	2014-04-07 10:56:27
156	SLIM04_AgQTOF02	IMS_Agilent_TOF_UIMF	SLIM	2952	3524	secfso	Active	EMSL 1526	WD59517 for AgQTOF02	2019-01-03 18:19:18
157	SLIM07_AgTOF08	IMS_Agilent_TOF_UIMF	SLIM	2953	4263	secfso	Active	EMSL 1422	WD56643 for AgTOF08; online, but not uploading data to DMS	2019-01-03 18:20:52
198	SLIM09_QExactP06	LTQ_FT	SLIM	4499	4500	fso	Active	EMSL 1426	SLIM instrument connected to QExactP06, brought online in 2023	2023-08-23 16:15:45
8	SW_TEST_FTICR	Finnigan_FTICR	Other	18	176	secfso	Inactive	n/a	FTICR TEST	2003-04-29 00:00:00
7	SW_TEST_LCQ	Finnigan_Ion_Trap	LCQ	16	195	fso	Inactive	n/a	LCQ TEST	2003-04-29 00:00:00
16	SW_Test_Bruker	BrukerFTMS	Other	87	177	fso	Inactive	n/a	Bruker SW Test Data	2003-04-29 00:00:00
72	SW_Test_Bruker_Imaging	BrukerMALDI_Imaging	Other	293	292	fso	Inactive	n/a	Dummy instrument for testing	2010-11-17 09:12:21
223	Samwise	Waters_Acquity_LC	Waters_Acquity_LC	4574	4917	secfso	Active	EMSL 1444	Waters nanoAcquity LC	2023-11-02 17:23:27
224	Sauron	Waters_Acquity_LC	Waters_Acquity_LC	4575	4918	secfso	Active	EMSL 1521	Waters nanoAcquity LC	2023-11-02 17:24:04
182	SciMax01	BrukerFT_BAF	Bruker_FTMS	3881	4993	secfso	Active	EMSL 1649	Bruker scimaX with ESI/MALDI source	2021-08-25 13:21:50
183	SciMax01_Imaging	BrukerMALDI_Imaging_V2	MALDI_Imaging	3881	4994	secfso	Active	EMSL 1649	Bruker scimaX with MALDI Imaging datasets	2021-08-25 13:23:06
251	Selma	Thermo_SII_LC	Thermo_SII_LC	4836	4940	secfso	Active	EMSL 1444	Vanquish Neo LC (binary pump and autosampler). Used for LCDatasetCapture tasks. The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets. Not EMSL owned	2024-05-21 20:10:14
163	Shimadzu_GC_MS_01	Shimadzu_GC	Shimadzu_GC	3094	3095	secfso	Offline	EMSL 1444	GC-2010 coupled to a GCMS-QP2010	2019-05-08 14:52:36
231	Smeagol	Waters_Acquity_LC	Waters_Acquity_LC	4582	4925	secfso	Active	EMSL 1314	Waters nanoAcquity LC	2023-11-03 10:18:01
155	SynaptG2_01	Waters_IMS	Waters_IMS	2929	4996	secfso	Active	EMSL 1142	Waters Synapt G2-Si, travelling wave IMS, with MALDI, MS:1002726	2018-11-26 11:19:39
104	TIMS_Maxis	IMS_Agilent_TOF_UIMF	IMS	1268	2860	secfso	Inactive	EMSL 1142	TIMS coupled with Maxis	2013-01-29 17:54:56
49	TSQ_1	Triple_Quad	TSQ	2317	2845	fso	Inactive	EMSL 1142	TSQ_Quantum Ultra for MRM-based experiments	2007-03-21 00:00:00
53	TSQ_2	Triple_Quad	TSQ	242	241	secfso	Inactive	EMSL 1521	TSQ Quantum Ultra for MRM-based experiments, Excessing July 2021	2008-12-29 00:00:00
56	TSQ_3	Triple_Quad	TSQ	252	4998	secfso	Offline	EMSL 1401	Thermo TSQ Vantage, MS:1001510	2009-05-29 00:00:00
105	TSQ_4	Triple_Quad	TSQ	1274	4999	secfso	Active	EMSL 1521	Thermo TSQ Vantage, MS:1001510	2013-03-13 17:35:14
126	TSQ_5	Triple_Quad	TSQ	1504	3270	secfso	Inactive	EMSL 1401	Thermo TSQ Vantage, MS:1001510	2014-06-26 12:04:38
125	TSQ_6	Triple_Quad	TSQ	1503	5000	secfso	Active	EMSL 1401	Thermo TSQ Vantage, MS:1001510	2014-06-24 17:42:18
215	Teton	Thermo_SII_LC	Thermo_SII_LC	4566	4909	secfso	Active	EMSL 1444	Vanquish Neo LC (binary pump, autosampler, and column compartment)	2023-11-01 10:16:16
84	Thermo_GC_MS_01	Triple_Quad	GC_TSQ	1006	3861	secfso	Inactive	EMSL 1142	GC-MS using a TSQ Quantum XLS; Currently in storage in EMSL 1346	2011-05-27 21:21:20
212	Titus	Thermo_SII_LC	Thermo_SII_LC	4563	4906	secfso	Active	EMSL 1526	Thermo RSLCnano Autosampler and pump	2023-11-01 10:13:27
235	Trillium	LCMSNet_LC	LCMSNet_LC	4586	4929	secfso	Active	EMSL 1142	LCMSNet LC with a VICI M60 infusion pump. Used for LCDatasetCapture tasks.  The defined auto storage path does not reference an actual server share since this instrument should not be used for datasets.	2023-11-06 11:13:36
115	UNC_VOrbiETD01	LTQ_FT	VelosOrbi	1444	1445	fso	Inactive	UNC (Chapel Hill, NC)	University of North Carolina LTQ-Velos Orbitrap	2014-03-07 15:39:51
85	VOrbi05	LTQ_FT	VelosOrbi	1009	5001	secfso	Active	EMSL 1429	LTQ Velos with an LTQ Orbitrap Velos (no ETD), MS:1000855	2011-06-02 11:20:25
58	VOrbiETD01	LTQ_FT	VelosOrbi	257	3857	secfso	Inactive	EMSL 1444	LTQ Velos Pro with an LTQ Orbitrap Velos Pro (supports ETD); for MassIVE, use LTQ Orbitrap Velos, MS:1001742	2009-08-10 00:00:00
60	VOrbiETD02	LTQ_FT	VelosOrbi	261	5002	secfso	Inactive	EMSL 1444	LTQ Velos with Orbitrap Elite (upgraded from an Orbitrap in October 2013); for MassIVE, use LTQ Orbitrap Velos, MS:1001742	2009-12-10 00:00:00
61	VOrbiETD03	LTQ_FT	VelosOrbi	263	4133	secfso	Inactive	EMSL 1526	LTQ Velos with an LTQ Orbitrap Velos (supports ETD); for MassIVE, use LTQ Orbitrap Velos, MS:1001742	2010-01-06 00:00:00
62	VOrbiETD04	LTQ_FT	VelosOrbi	265	3859	secfso	Inactive	EMSL 1526	Velos Pro with an LTQ Orbitrap Velos (supports ETD); for MassIVE, use LTQ Orbitrap Velos, MS:1001742	2010-01-16 00:00:00
93	VPro01	Finnigan_Ion_Trap	VelosPro	1162	1345	secfso	Inactive	EMSL 1621	Velos Pro Ion Trap	2012-07-13 14:11:46
89	Vanderbilt_VOrbiETD01	LTQ_FT	VelosOrbi	1098	1446	fso	Inactive	VU (Tennessee)	Vanderbilt Institute LTQ-Velos Orbitrap	2012-03-21 13:19:23
90	WashU_TripleTOF5600	Sciex_TripleTOF	Sciex_TripleTOF	1133	1134	fso	Inactive	WUSL (Washington University in St. Louis)	Data acquired under the CPTAC project	2012-05-14 20:28:39
174	XevoG2_01	Waters_TOF	Waters_TOF	3536	5003	secfso	Active	BSF 1215	Transfer/Moved from BSEL in September 2020	2020-09-23 12:48:22
255	timsTOFFlex02	BrukerTOF_TDF	timsTOF_Flex	4863	4997	secfso	Active	EMSL 1444	Bruker timsTOF Flex with ESI source. Also has MALDI imaging capability	2024-07-03 13:46:33
256	timsTOFFlex02_Imaging	timsTOF_MALDI_Imaging	MALDI_timsTOF_Imaging	4863	4962	secfso	Active	EMSL 1444	Bruker timsTOF Flex with MALDI imaging capability	2024-07-03 13:47:58
194	timsTOFScp01	BrukerTOF_TDF	timsTOF_SCP	4442	5004	secfso	Active	EMSL 1314	Bruker timsTOF for single cell proteomics; for MassIVE, use timsTOF SCP, MS:1003231	2023-04-19 16:36:27
\.


--
-- PostgreSQL database dump complete
--

