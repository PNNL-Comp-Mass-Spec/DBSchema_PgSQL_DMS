--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
-- Dumped by pg_dump version 16.1

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
-- Data for Name: t_filter_set_criteria_names; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_filter_set_criteria_names (criterion_id, criterion_name, criterion_description) FROM stdin;
1	Spectrum_Count	Number of distinct spectra the peptide is observed in, taking into account datasets analyzed multiple times
2	Charge	Peptide charge
3	High_Normalized_Score	Highest normalized score (e.g. XCorr for Sequest) observed
4	Cleavage_State	For trypsin, 2=fully tryptic, 1=partially tryptic, 0=non tryptic
5	Peptide_Length	Number of residues in the peptide
6	Mass	Peptide mass
7	DelCn	DeltaCn value, the normalized difference between the given peptide's XCorr and the highest scoring peptide's XCorr
8	DelCn2	DeltaCn2 value, the normalized difference between the given peptide's XCorr and the next lower scoring peptide's XCorr (DeltaCN2 for XTandem is Hyperscore-based; DeltaCN2 for Inspect is DeltaNormTotalPRMScore)
9	Discriminant_Score	Sequest-based discriminant score
10	NET_Difference_Absolute	Absolute value of the difference between observed normalized elution time (NET) and predicted NET
11	Discriminant_Initial_Filter	Filter based on Xcorr, DelCN, RankXc and the number of tryptic termini (PassFilt column in synopsis and fht files)
12	Protein_Count	Count of the number of proteins that a given peptide sequence is found in
13	Terminus_State	Non-zero if peptide is at terminus of protein; 1=N-terminus, 2=C-terminus, 3=N and C-terminus
14	XTandem_Hyperscore	XTandem Hyperscore
15	XTandem_LogEValue	XTandem E-Value (base-10 log)
16	Peptide_Prophet_Probability	Sequest-based probability developed by Andrew Keller; for Inspect, use 1-PValue; in both cases, closer to 1 is higher confidence
17	RankScore	The rank of the given peptides score within the given scan; for Sequest, this is RankXc; for Inspect this is RankFScore
18	Inspect_MQScore	Inspect MQScore
19	Inspect_TotalPRMScore	Inspect TotalPRMScore
20	Inspect_FScore	Inspect FScore
21	Inspect_PValue	Inspect PValue
22	MSGF_SpecProb	MSGF Spectrum Probability value; closer to 0 is higher confidence
23	MSGFDB_SpecProb	MSGFDB Spectrum Probability; closer to 0 is higher confidence
24	MSGFDB_PValue	MSGFDB PValue
25	MSGFPlus_QValue	MSGF+ QValue (aka FDR for MSGFDB)
26	MSAlign_PValue	MSAlign PValue
27	MSAlign_FDR	MSAlign FDR
28	MSGFPlus_PepQValue	MSGF+ PepQValue (aka PepFDR for MSGFDB)
\.


--
-- Name: t_filter_set_criteria_names_criterion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_filter_set_criteria_names_criterion_id_seq', 28, true);


--
-- PostgreSQL database dump complete
--

