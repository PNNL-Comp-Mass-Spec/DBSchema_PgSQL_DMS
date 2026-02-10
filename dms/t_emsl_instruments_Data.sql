--
-- PostgreSQL database dump
--

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

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
-- Data for Name: t_emsl_instruments; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_emsl_instruments (eus_instrument_id, eus_display_name, eus_instrument_name, eus_available_hours, local_category_name, local_instrument_name, last_affected, eus_active_sw, eus_primary_instrument) FROM stdin;
1009	Mass Spectrometer: Fourier-Transform	Mass Spectrometer: 7-Tesla, Electrospray Ionization FTICR	10	\N	\N	2024-08-06 06:15:53	0	0
1010	Mass Spectrometer: Finnigan LCQ Classic #1	Mass Spectrometer: Finnigan LCQ Classic #1	24	\N	\N	2024-08-06 06:15:53	0	0
1011	Mass Spectrometer: MALDI TOF	Mass Spectrometer: MALDI TOF	10	\N	\N	2024-08-06 06:15:53	0	0
1012	Mass Spectrometer: Micromass ZabSpec oaTOF	Mass Spectrometer: Micromass ZabSpec oaTOF	10	\N	\N	2024-08-06 06:15:53	0	0
1013	Mass Spectrometer: Finnigan TSQ 7000 Triple Quadrupole	Mass Spectrometer: Finnigan TSQ 7000 Triple Quadrupole	10	\N	\N	2024-08-06 06:15:53	0	0
1014	Mass Spectrometer: 3.5-tesla, Wide Bore FTICR	Mass Spectrometer: 3.5-tesla, Wide Bore FTICR	10	\N	\N	2024-08-06 06:15:53	0	0
1015	Mass Spectrometer: Fourier-Transform	Mass Spectrometer: 11.5-Tesla, Wide Bore FTICR	10	\N	\N	2024-08-06 06:15:53	0	0
1020	Mass Spectrometer: Time of Flight Secondary Ion (ToF SIMS) - 1997	Mass Spectrometer: Time of Flight Secondary Ion (ToF SIMS) - 1997	10	\N	\N	2024-08-06 06:15:53	0	0
1033	Mass Spectrometer: Laser Desorption - Ion Trap	Mass Spectrometer: Laser Desorption - Ion Trap	10	\N	\N	2024-08-06 06:15:53	0	0
1062	Mass Spectrometer: General Analytical	Mass Spectrometer: General Analytical	24	\N	\N	2024-08-06 06:15:53	0	0
1080	Mass Spectrometer: FT-ICR, 6T (Ion Surface Collisions)	Mass Spectrometer: 6T FTICR (for Ion Surface Collisions)	10	\N	\N	2024-08-06 06:15:53	0	0
1099	Inductively Coupled Plasma (ICP-MS)	Mass Spectrometer: ICP-MS (2008)	10	\N	\N	2024-08-06 06:15:53	0	0
1153	Mass Spectrometer: Time-of-Flight (ToF)	Mass Spectrometer: Quadrupole TOF Micromass Q-TOF Ultima	10	\N	\N	2024-08-06 06:15:53	0	0
1161	Mass Spectrometer: Finnigan LCQ Classic #2	Mass Spectrometer: Finnigan LCQ Classic #2	24	\N	\N	2024-08-06 06:15:53	0	0
1162	Mass Spectrometer: Finnigan LCQ DUO #1	Mass Spectrometer: Finnigan LCQ DUO #1	24	\N	\N	2024-08-06 06:15:53	0	0
1163	Mass Spectrometer: Finnigan LCQ DUO #2	Mass Spectrometer: Finnigan LCQ DUO #2	24	\N	\N	2024-08-06 06:15:53	0	0
1164	Mass Spectrometer: Finnigan LCQ XPDECA #1	Mass Spectrometer: Finnigan LCQ XPDECA #1	10	\N	\N	2024-08-06 06:15:53	0	0
1173	Mass Spectrometer: Proton Transfer Reaction (PTRMS)	Mass Spectrometer: Proton Transfer Reaction (PTRMS)	10	\N	\N	2024-08-06 06:15:53	0	0
33200	Mass Spectrometer: Fourier-Transform Ion Cyclotron Resonance	Mass Spectrometer: 9.4-Tesla, 160mm Bore FTICR	24	Mass Spectrometer:  Fourier-Transform Ion Cyclotron Resonance	\N	2024-08-06 06:15:53	0	0
34006	Time-of-Flight Aerosol Mass Spectrometer (TOF-AMS)	Mass Spectrometer: TOF AMS-HR (2002)	10	\N	\N	2024-08-06 06:15:53	0	0
34010	Mass Spectrometer: Finnigan LCQ XPDECA #2	Mass Spectrometer: Finnigan LCQ XPDECA #2	24	\N	\N	2024-08-06 06:15:53	0	0
34011	Fourier-Transform Ion Cyclotron Resonance (FTICR)	Mass Spectrometer: 12T FTICR MALDI (2004)	10	Mass Spectrometer:  Fourier-Transform Ion Cyclotron Resonance	\N	2025-11-27 06:16:47.898581	1	1
34012	Mass Spectrometer: Linear Ion trap (LTQ)	Mass Spectrometer: LTQ2	24	\N	\N	2024-08-06 06:15:53	0	0
34013	Mass Spectrometer: Linear Ion trap (LTQ)	Mass Spectrometer: LTQ3	24	\N	\N	2024-08-06 06:15:53	0	0
34014	Mass Spectrometer: Fourier-Transform Ion Cyclotron Resonance	Mass Spectrometer: LTQFT1	24	\N	\N	2024-08-06 06:15:53	0	0
34015	Mass Spectrometer: Linear Ion trap (LTQ)	Mass Spectrometer: LTQ1	10	\N	\N	2024-08-06 06:15:53	0	0
34016	Mass Spectrometer: Q-STARR	Mass Spectrometer: Q-STARR	10	\N	\N	2024-08-06 06:15:53	0	0
34017	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: ToF LC-MS 2 (2004)	10	\N	Mass Spectrometry: Ion Mobility Spectrometry, TOF (IMS_TOF2)	2025-11-05 06:16:35.721245	0	0
34020	Mass Spectrometer: Single Particle (SPLAT II)	Mass Spectrometer: Single Particle (SPLAT II)	10	\N	\N	2023-12-18 06:15:32	1	0
34029	GC-MS, Volatile Organic Compounds	Mass Spectrometer: GC-MS (2005)	10	\N	\N	2025-11-27 06:16:47.898581	0	0
34034	Mass Spectrometer: Linear Ion trap (LTQ)	Mass Spectrometer: LTQ4	10	\N	\N	2024-08-06 06:15:53	0	0
34035	Mass Spectrometer: Orbitrap	Mass Spectrometer: LTQ_Orb 1	10	Mass Spectrometer: ORB-LTQ	\N	2024-08-06 06:15:53	0	0
34037	Mass Spectrometer: Ion Mobility Spectrometry, Time of Flight	Mass Spectrometer: Agilent TOF1	10	\N	Mass Spectrometry: Ion Mobility Spectrometry, TOF (IMS_TOF1)	2024-08-06 06:15:53	0	0
34038	Mass Spectrometer: Agilent Ion Trap	Mass Spectrometer: Agilent_XCT1	10	\N	\N	2024-08-06 06:15:53	0	0
34039	Mass Spectrometer: Agilent single quad	Mass Spectrometer: Agilent single quad	10	\N	\N	2024-08-06 06:15:53	0	0
34060	Mass Spectrometer: Aerosol - time-of-flight	Mass Spectrometer: Aerosol - time-of-flight - standard	10	\N	\N	2024-08-06 06:15:53	0	0
34062	Mass Spectrometer: Ion Mobility	Mass Spectrometer: Time of Flight	10	\N	\N	2024-08-06 06:15:53	0	0
34068	Mass Spectrometer: Linear Ion Trap Quadrupole (LTQ) Orbitrap MS - for environmental research (nanoDESI)	Mass Spectrometer: Linear Ion Trap Quadrupole (LTQ) Orbitrap - environmental research	10	\N	\N	2024-08-06 06:15:53	0	0
34070	Mass Spectrometer: Orbitrap	Mass Spectrometer: LTQ_Orb 2	24	Mass Spectrometer: ORB-LTQ	\N	2024-08-06 06:15:53	0	0
34073	Time of Flight-Secondary Ion Mass Spectrometer (TOF-SIMS)	Mass Spectrometer: Time of Flight-Secondary Ion Mass Spectrometer (TOF-SIMS)	10	\N	\N	2024-08-06 06:15:53	0	0
34074	Mass Spectrometer: Orbitrap	Mass Spectrometer: LTQ_Orb 3	24	Mass Spectrometer: ORB-LTQ	\N	2024-08-06 06:15:53	0	0
34078	Secondary Ion Mass Spectrometry (ToF-SIMS)	Mass Spectrometer: TOF-SIMS (2007)	10	\N	\N	2024-08-06 06:15:53	1	1
34080	Mass Spectrometer: Linear Ion trap (LTQ)	Mass Spectrometer: ETD_LTQ1	10	\N	\N	2024-08-06 06:15:53	0	0
34081	Mass Spectrometer: LC Triple Quadrupole	Mass Spectrometer: TSQ_1	10	Mass Spectrometer:  LC-QQQ	\N	2024-08-06 06:15:53	0	0
34094	Mass Spectrometer: Isotope Ratio	Mass Spectrometer: Isotope Ratio	24	\N	\N	2024-08-06 06:15:53	0	0
34097	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Quad TSQ LC-MS 2 (2008)	10	Mass Spectrometer:  LC-QQQ	\N	2025-08-20 06:16:11.319862	0	0
34098	Mass Spectrometer: Time-of-Flight (ToF)	Mass Spectrometer: Agilent Q-TOF1	10	\N	\N	2024-08-06 06:15:53	0	0
34099	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: IMS 5 Ag-QToF 4 (2008)	10	\N	Mass Spectrometry: Ion Mobility Spectrometry, TOF (IMS_TOF3)	2025-11-25 06:16:47.846159	0	0
34100	Mass Spectrometer: HP ion trap	Mass Spectrometer: HP ion trap	10	\N	\N	2024-08-06 06:15:53	0	0
34111	Mass Spectrometer: Orbitrap	Mass Spectrometer: Exactive 1	10	Mass Spectrometer: ORB-Exactive	\N	2024-08-06 06:15:53	0	0
34112	Mass Spectrometer: Orbitrap	Mass Spectrometer: Exactive 4	10	Mass Spectrometer: ORB-Exactive	\N	2024-08-06 06:15:53	0	0
34113	Mass Spectrometer: Orbitrap	Mass Spectrometer: Exactive 3	10	Mass Spectrometer: ORB-Exactive	\N	2024-08-06 06:15:53	0	0
34114	Mass Spectrometer: Orbitrap	Mass Spectrometer: LTQ_Orb_Velos 1	24	Mass Spectrometer: ORB-LTQ	\N	2024-08-06 06:15:53	0	0
34115	Lipidomics Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Velos Orbitrap Elite 2 (2009)	24	Mass Spectrometer: ORB-LTQ	\N	2025-11-08 06:16:35.69617	0	0
34116	Mass Spectrometer: Orbitrap	Mass Spectrometer: LTQ_Orb_Velos 3	24	Mass Spectrometer: ORB-LTQ	\N	2024-08-06 06:15:53	0	0
34127	Mass Spectrometer: Orbitrap	Mass Spectrometer: LTQ_Orb_Velos 4	24	Mass Spectrometer: ORB-LTQ	\N	2024-08-06 06:15:53	0	0
34139	Fourier-Transform Ion Cyclotron Resonance (FTICR)	Mass Spectrometer: 15T FTICR (2010)	10	Mass Spectrometer:  Fourier-Transform Ion Cyclotron Resonance	\N	2024-08-06 06:15:53	0	1
34145	Mass Spectrometer: MALDI-TOF	Mass Spectrometer: Maxis_01	10	Mass Spectrometer: Imaging-MS	\N	2024-08-06 06:15:53	0	0
34146	Mass Spectrometer: MALDI FTICR 	Mass Spectrometer: MALDI FTICR	10	Mass Spectrometer: Imaging-MS	Mass Spectrometer: MALDI 9.4T FTICR	2024-08-07 06:16:00.891027	0	0
34149	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Vantage Triple Quad TSQ 3 (2009)	10	Mass Spectrometer:  LC-QQQ	\N	2025-11-25 06:16:47.846159	0	0
34150	Metabolomic Gas Chromatography-Mass Spectrometry (GC-MS)	Mass Spectrometer: Agilent GC-MS 1 (2009)	10	Mass Spectrometry:  GC-MS	\N	2024-12-05 06:16:46.760634	1	0
34152	Mass Spectrometer: GC-MS (metabolomics)	Mass Spectrometer: Thermo_GC_MS_01	10	Mass Spectrometry:  GC-MS	\N	2024-08-06 06:15:53	0	0
34153	Mass Spectrometer: Chromatograph, Liquid, qTRAP	Mass Spectrometer: QTrap01	24	Mass Spectrometer:  LC-QQQ	\N	2024-08-06 06:15:53	0	0
34154	Lipidomics Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Ag-QToF 3 (2010)	10	Mass Spectrometer:  Ion Mobility Time of Flight	Mass Spectrometry: Ion Mobility Spectrometry, TOF (IMS_TOF4)	2025-11-25 06:16:47.846159	0	0
34155	Lipidomics Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Ag-TOF 2 (2004)	10	Mass Spectrometer:  Ion Mobility Time of Flight	Mass Spectrometry: Ion Mobility Spectrometry, TOF (IMS_TOF6)	2025-11-25 06:16:47.846159	0	0
34156	Liquid Chromatography - Ion Mobility Spectrometry - Mass Spectrometry (LC-IMS-MS)	Mass Spectrometer: IMS 3 Ag-QToF 1 (2010)	10	Mass Spectrometer:  Ion Mobility Time of Flight	Mass Spectrometry: Ion Mobility Spectrometry, TOF (IMS_TOF5)	2025-11-25 06:16:47.846159	1	0
34157	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: ToF LC-MS 5 (2009)	10	Mass Spectrometer:  Ion Mobility Time of Flight	Mass Spectrometry: Ion Mobility Spectrometry, TOF (IMS_TOF7)	2024-08-06 06:15:53	1	0
34158	Inductively Coupled Plasma (ICP-MS)	Mass Spectrometer: ICP-MS (2011)	10	\N	\N	2024-08-06 06:15:53	0	0
34159	LTQ for nanoPOTS prep	Mass Spectrometer: nanoPOTS preparation	10	\N	\N	2023-12-18 06:15:32	1	0
34160	Inductively Coupled Plasma (ICP-MS)	Mass Spectrometer: ICP-MS Multi-Collector (2011)	10	\N	\N	2024-08-06 06:15:53	0	0
34161	Inductively Coupled Plasma (ICP-MS)	Mass Spectrometer: ICP-MS Metallomics (2010)	10	\N	\N	2024-08-06 06:15:53	0	0
34172	Lipidomics Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Slim 1 AgQ-ToF 4 (2010)	10	\N	\N	2025-11-25 06:16:47.846159	0	0
34173	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: SLIM 3 Ag-TOF 6 (2009)	10	\N	\N	2025-11-27 06:16:47.898581	0	0
34174	Liquid Chromatography - Ion Mobility Spectrometry - Mass Spectrometry (LC-IMS-MS)	Mass Spectrometer: IMS 6 Ag-ToF 7 (2010)	10	\N	\N	2025-11-25 06:16:47.846159	0	0
34175	Aerosol Mass Spectrometry (MS) Nanospray Desorption Electrospray Ionization (nano-DESI)	Mass Spectrometer: nanoDESI Velos Orbitrap 05 (2011)	24	\N	\N	2025-11-25 06:16:47.846159	1	0
34182	Nanoscale Secondary Ion Mass Spectrometry (NanoSIMS)	Mass Spectrometer: NanoSIMS (2012)	10	\N	\N	2024-08-06 06:15:53	1	1
34184	Ion Chromatography (IC)	Mass Spectrometer: Agilent 1 (2008)	10	\N	\N	2024-08-06 06:15:53	0	0
34185	Ion Chromatography (IC)	Mass Spectrometer: Agilent 2 (2010)	10	\N	\N	2024-08-06 06:15:53	0	0
34189	Ion Chromatography (IC)	Mass Spectrometer: Agilent 3 (2010)	10	\N	\N	2025-11-05 06:16:35.721245	0	0
34194	Metabolomic Gas Chromatography-Mass Spectrometry (GC-MS)	Mass Spectrometer: Agilent GC-MS 2 (2012)	10	\N	\N	2024-12-05 06:16:46.760634	1	0
34195	Mass Spectrometer: QExact01	Mass Spectrometer: QExact01	24	\N	\N	2024-08-06 06:15:53	0	0
34197	Mass Spectrometer: Laser Ablation Sampling System	Laser Ablation Sampling System	10	\N	\N	2021-05-11 06:15:03	Y	N
34210	Mass Spectrometer: Waters Xevo TQ-S	Mass Spectrometer: Waters Xevo TQ-S	10	\N	\N	2024-08-06 06:15:53	0	0
34211	Mass Spectrometer: Agilent_QQQ_03	Mass Spectrometer: Agilent Triple Quadrupole 03	10	\N	\N	2024-08-06 06:15:53	0	0
34212	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Agilent QQQ (Triple Quad) 4 (2012)	10	\N	\N	2025-11-27 06:16:47.898581	1	0
34213	Mass Spectrometer: PentaQuad	Mass Spectrometer: PentaQuad	10	\N	\N	2024-08-06 06:15:53	0	0
34214	Mass Spectrometer: TSQ_4	Mass Spectrometer: TSQ_4	10	\N	\N	2024-08-06 06:15:53	0	0
34215	Mass Spectrometer: TSQ_5	Mass Spectrometer: TSQ_5	10	\N	\N	2024-08-06 06:15:53	0	0
34225	Fourier-Transform Ion Cyclotron Resonance (FTICR)	Mass Spectrometer: 21T FTICR (2012)	10	\N	\N	2024-08-06 06:15:53	1	1
34228	Proteomic Bottom-up (Global) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: LESA QE Plus Orbitrap 2 (2014)	24	\N	\N	2025-11-27 06:16:47.898581	1	1
34229	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Vantage Triple Quad TSQ 6 (2014)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
34230	Mass Spectrometer: FTICR-SIMS	Mass Spectrometer: 7.0 Tesla, 160mm Bore FTICR	10	\N	\N	2024-08-06 06:15:53	0	0
34231	Proteomic Bottom-up (Global) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: QE HF Orbitrap 3 (2015)	24	\N	\N	2025-11-27 06:16:47.898581	1	1
34232	Proteomic Bottom-up (Global) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: QE Plus Orbitrap 4 (2015)	24	\N	\N	2025-11-27 06:16:47.898581	1	1
34233	Mass Spectrometer: Shimadzu RTMS	Mass Spectrometer: Shimadzu RTMS	10	\N	\N	2023-12-18 06:15:32	0	0
34234	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Quad TSQ LC-MS 5 (2013)	10	\N	\N	2025-08-20 06:16:11.319862	0	0
34235	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Vantage Triple Quad TSQ 4 (2013)	10	\N	\N	2025-11-27 06:16:47.898581	1	0
34236	Mass Spectrometer: Agilent_QQQ_01	Mass Spectrometer: Agilent_QQQ_01	10	\N	\N	2024-08-06 06:15:53	0	0
34237	Mass Spectrometer: Ozone NS	Mass Spectrometer: Ozone NS	10	\N	\N	2024-08-06 06:15:53	0	0
34244	Metabolomic Gas Chromatography-Mass Spectrometry (GC-MS)	Mass Spectrometer: Q Exactive GC-MS (2016)	24	\N	\N	2025-11-27 06:16:47.898581	0	0
34245	Proteomic Top-down (Intact) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Fusion Lumos Orbitrap LC-MS 1 (2015)	24	\N	\N	2025-08-20 06:16:11.319862	1	1
34253	Time-of-Flight Aerosol Mass Spectrometer (TOF-AMS)	Mass Spectrometer: TOF-AMS (2016)	10	\N	\N	2024-08-06 06:15:53	1	0
34254	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: QE Plus Orbitrap 6 (2020)	24	\N	\N	2025-11-25 06:16:47.846159	1	1
34255	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Altis Triple Quad 1 (2017)	24	\N	\N	2025-11-25 06:16:47.846159	1	0
34256	Proteomic Bottom-up (Global) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: UHMR QE HF Orbitrap 5 (2015)	10	\N	\N	2025-11-27 06:16:47.898581	1	0
34258	Liquid Chromatography - Ion Mobility Spectrometry - Mass Spectrometry (LC-IMS-MS)	Mass Spectrometer: Q-ToF LC-IMS 5 (2013)	24	\N	\N	2025-06-26 06:16:10.244553	0	0
34259	Liquid Chromatography - Ion Mobility Spectrometry - Mass Spectrometry (LC-IMS-MS)	Mass Spectrometer: IMS 9 Ag-QToF 6 (2015)	24	\N	\N	2025-11-27 06:16:47.898581	1	0
34260	Metabolomic Gas Chromatography-Mass Spectrometry (GC-MS)	Mass Spectrometer: Agilent GC-MS 4 (2012)	10	\N	\N	2024-12-05 06:16:46.760634	0	0
34264	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Slim 7 Ag-ToF 8 (2017)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
34267	Proteomic Top-down (Native) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Lumos 2 (2017)	24	\N	\N	2025-11-26 06:16:47.700399	1	0
34281	Mass Spectrometry (MS) Imaging	Mass Spectrometer: Waters Synapt G2 QToF 1 (2018)	10	\N	\N	2025-11-25 06:16:47.846159	1	1
34285	Mass Spectrometer: Laser Ablation Isotope Ratio	Laser Ablation IRMS (IRMS 3)	10	\N	\N	2021-05-11 06:15:03	Y	N
34286	Mass Spectrometer: Gas Chromatograph Isotope Ratio	Isotope Ratio Mass Spectrometry (IRMS 2)	10	\N	\N	2021-05-11 06:15:03	Y	N
34287	Mass Spectrometer: Elemental Analyzer Isotope Ratio	Isotope Ratio Mass Spectrometry (IRMS 1)	10	\N	\N	2021-05-11 06:15:03	Y	N
34289	Liquid Chromatography - Ion Mobility Spectrometry - Mass Spectrometry (LC-IMS-MS)	Mass Spectrometer: IMS 10 Ag-QToF 7 (2018)	24	\N	\N	2025-11-27 06:16:47.898581	1	0
34297	Proteomic Bottom-up (Global) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: QE HFX Orbitrap 1 (2019)	24	\N	\N	2025-11-27 06:16:47.898581	1	1
34298	Proteomic Bottom-up (Global) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: QE HFX Orbitrap 2 (2020)	24	\N	\N	2025-11-27 06:16:47.898581	1	1
34307	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Altis Triple Quad 3 (2019)	24	\N	\N	2025-11-25 06:16:47.846159	1	0
34308	Proteomic Bottom-up (Global) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: QE HFX Orbitrap 3 (2019)	24	\N	\N	2025-11-27 06:16:47.898581	1	0
34313	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Eclipse Orbitrap 1 (2020)	24	\N	\N	2025-11-26 06:16:47.700399	1	1
34314	Mass Spectrometer: AgQToF	Mass Spectrometer: AgQToF	24	\N	\N	2024-08-06 06:15:53	0	1
34321	Proteomic Bottom-up (Labeled) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Eclipse Orbitrap 2 (2020)	24	\N	\N	2025-11-27 06:16:47.898581	1	0
34322	Proteomic Bottom-up (Labeled) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Exploris Orbitrap 1 (2020)	10	\N	\N	2025-11-27 06:16:47.898581	1	0
34331	Pyrolysis Gas Chromatography-Mass Spectrometry (GC-MS)	Mass Spectrometer: Pyrolysis GC-MS (2019)	10	\N	\N	2024-08-06 06:15:53	1	0
34332	Fourier-Transform Ion Cyclotron Resonance (FTICR)	Mass Spectrometer: 7T FTICR SciMax01 (2021)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35000	Mass Spectrometer: SciMax	Mass Spectrometer: SciMax01	10	\N	\N	2021-11-30 06:15:04	0	0
35007	Metabolomic Gas Chromatography-Mass Spectrometry (GC-MS)	Mass Spectrometer: Agilent GC-MS 3 (2021)	24	\N	\N	2024-12-05 06:16:46.760634	1	0
35011	Aerosol Thermal Desorption Gas Chromatography-Mass Spectrometry (TD-GC-MS)\n	Thermal Desorption GC-QTOFMS (2022)\n	\N	\N	\N	2026-02-06 19:15:29.097798	\N	\N
35015	Proteomic Bottom-up (NanoScale) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: TIMS ToF SCP 1 (2023)	24	\N	\N	2025-11-25 06:16:47.846159	1	0
35022	Inductively Coupled Plasma (ICP-MS) 	Mass Spectrometer: ICP-MS (2023)	10	\N	\N	2024-08-07 06:16:00.891027	1	0
35024	Liquid Chromatography - Ion Mobility Spectrometry - Mass Spectrometry (LC-IMS-MS)	Mass Spectrometer: IMS 12 Ag-QToF 9 (2023)	10	\N	\N	2026-01-30 06:16:50.156536	1	0
35025	Lipidomics Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Q-ToF LC-MS 3 (2010) - DUPLICATE	\N	\N	\N	2024-08-06 06:15:53	0	0
35026	Lipidomics Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Q-ToF LC-MS 2 (2010) - DUPLICATE	\N	\N	\N	2024-08-06 06:15:53	0	0
35027	Proteomic Bottom-up (Labeled) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Ascend Orbitrap 1 (2023)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35028	Proteomic Bottom-up (Labeled) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Exploris Orbitrap 2 (2022)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35029	Proteomic Bottom-up (Labeled) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Exploris Orbitrap 3 (2023)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35030	Proteomic Bottom-up (Labeled) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Exploris Orbitrap 4 (2023)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35031	Lipidomics Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Lumos03 (2018)	10	\N	\N	2025-11-26 06:16:47.700399	1	0
35032	Top-down (Intact) Proteomic Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Q Exactive HF UHMR 5 (2015) - DUPLICATE	\N	\N	\N	2024-08-06 06:15:53	0	0
35033	Metabolomic Liquid State Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Q Exactive LC-MS 6 (2023) - DUPLICATE	\N	\N	\N	2024-08-06 06:15:53	0	0
35034	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Altis Triple Quad LC-MS 1 (2017) - DUPLICATE	10	\N	\N	2025-08-20 06:16:11.319862	0	0
35035	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Altis Triple Quad 2 (2018)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35036	Liquid State Nuclear Magnetic Resonance (lsNMR)	Mass Spectrometer: lsNMR HPLC (2019)	10	\N	\N	2024-10-29 06:16:37.644656	1	0
35037	Metabolomic Gas Chromatography-Mass Spectrometry (GC-MS)	Mass Spectrometer: Ag-ToF 10 (2022)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35038	Fourier-Transform Ion Cyclotron Resonance (FTICR)	Mass Spectrometer: 12T FTICR-MALDI (2004) - DUPLICATE	\N	\N	\N	2024-08-06 06:15:53	0	0
35046	Aerosol Mass Spectrometry (MS) Nanospray Desorption Electrospray Ionization (nano-DESI)	Mass Spectrometer: nano-DESI Exploris Orbitrap MX 1 (2024)	10	\N	\N	2025-11-25 06:16:47.846159	1	0
35047	Mass Spectrometry (MS) Imaging	Mass Spectrometer: TIMS ToF Flex 1 (2024)	10	\N	\N	2025-11-27 06:16:47.898581	1	0
35064	Proteomic Bottom-up (Labeled) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Exploris Orbitrap 6 (2023)	24	\N	\N	2025-11-27 06:16:47.898581	1	0
35067	Proteomic Bottom-up (Targeted) Liquid Chromatography-Mass Spectrometry (LC-MS)	Mass Spectrometer: Altis Triple Quad 4 (2024)	24	\N	\N	2025-11-25 06:16:47.846159	1	0
\.


--
-- PostgreSQL database dump complete
--

