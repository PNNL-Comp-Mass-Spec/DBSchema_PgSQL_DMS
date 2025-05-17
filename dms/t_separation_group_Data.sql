--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
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
-- Data for Name: t_separation_group; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_separation_group (separation_group, comment, active, sample_prep_visible, fraction_count) FROM stdin;
CE		1	0	0
Evosep_100_SPD_11min		1	1	0
Evosep_200_SPD_6min		1	1	0
Evosep_300_SPD_3min		1	1	0
Evosep_30_SPD_44min		1	1	0
Evosep_60_SPD_21min		1	1	0
Evosep_Whisper_20_SPD_60min		1	1	0
Evosep_Whisper_40_SPD_30min		1	1	0
Evosep_extended_15_SPD_88min		1	1	0
GC		1	1	0
Glycans		0	0	0
Infusion	Direction infusion	1	1	0
LC-2D-Custom		1	1	0
LC-2D-Formic		1	1	0
LC-2D-HILIC		1	1	0
LC-Acetylome		1	1	0
LC-Agilent-2D-Intact		1	0	0
LC-Eksigent		0	0	0
LC-Formic_100min		0	0	0
LC-Formic_10min		1	1	0
LC-Formic_150min		1	1	0
LC-Formic_15min		1	1	0
LC-Formic_1hr		1	1	0
LC-Formic_20min		1	1	0
LC-Formic_20min_70SPD	Trap and Elute	1	1	0
LC-Formic_2hr		1	1	0
LC-Formic_30min		1	1	0
LC-Formic_3hr		1	1	0
LC-Formic_45min		0	0	0
LC-Formic_4hr		1	1	0
LC-Formic_5hr		1	0	0
LC-Formic_80min		0	0	0
LC-Formic_90min		1	1	0
LC-GlcNAc		1	1	0
LC-HILIC		1	1	0
LC-HiFlow	High flow LC (analytical LC)	1	1	0
LC-IMER-ND_2hr		1	0	0
LC-IMER-ND_3hr		1	0	0
LC-IMER_2hr		0	0	0
LC-IMER_3hr		1	1	0
LC-IMER_5hr		1	0	0
LC-IntactProtein_200min		1	1	0
LC-IonPairing		1	0	0
LC-Metabolomics_LipidSoluble		1	1	0
LC-Metabolomics_LipidSoluble_25MinGradient		1	1	0
LC-Metabolomics_Oxylipids		1	1	0
LC-Metabolomics_Sonnenburg		1	1	0
LC-Metabolomics_WaterSoluble		1	1	0
LC-MicroHpH-12	Use for placeholder requested runs that can be converted into requested run fractions	1	0	12
LC-MicroHpH-24	Use for placeholder requested runs that can be converted into requested run fractions	1	0	24
LC-MicroHpH-3	Use for placeholder requested runs that can be converted into requested run fractions	1	0	3
LC-MicroHpH-4	Use for placeholder requested runs that can be converted into requested run fractions	1	0	4
LC-MicroHpH-6	Use for placeholder requested runs that can be converted into requested run fractions	1	0	6
LC-MicroHpH-96	Use for placeholder requested runs that can be converted into requested run fractions	1	0	96
LC-MicroSCX-12	Use for placeholder requested runs that can be converted into requested run fractions	1	0	12
LC-MicroSCX-6	Use for placeholder requested runs that can be converted into requested run fractions	1	0	6
LC-NanoHpH-12	Use for placeholder requested runs that can be converted into requested run fractions	1	0	12
LC-NanoHpH-24	Use for placeholder requested runs that can be converted into requested run fractions	1	0	24
LC-NanoHpH-6	Use for placeholder requested runs that can be converted into requested run fractions	1	0	6
LC-NanoHpH-96	Use for placeholder requested runs that can be converted into requested run fractions	1	0	96
LC-NanoPot_100min	NanoPot separations	1	0	0
LC-NanoPot_1hr	NanoPot separations	1	0	0
LC-NanoPot_2hr	NanoPot separations	1	0	0
LC-NanoPot_30min	NanoPot separations	1	0	0
LC-NanoPot_3hr	NanoPot separations	1	0	0
LC-NanoSCX-12	Use for placeholder requested runs that can be converted into requested run fractions	1	0	12
LC-NanoSCX-6	Use for placeholder requested runs that can be converted into requested run fractions	1	0	6
LC-PCR-Tube		1	0	0
LC-PRISM		1	0	0
LC-Phospho		1	1	0
LC-ReproSil-75um		1	1	0
LC-Ribose_2hr		1	1	0
LC-TFA_100minute		1	0	0
LC-Ubiquitylome		1	1	0
LC-Waters-NH4HCO2		1	0	0
LC-Waters_High_pH		1	1	0
LC-Waters_Neutral		1	1	0
Other		1	1	0
RapidFire-SPE		1	1	0
\.


--
-- PostgreSQL database dump complete
--

