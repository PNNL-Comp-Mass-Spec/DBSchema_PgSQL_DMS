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
-- Data for Name: t_internal_std_components; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_internal_std_components (internal_std_component_id, name, description, monoisotopic_mass, charge_minimum, charge_maximum, charge_highest_abu, expected_ganet) FROM stdin;
10	Pep-09	ASHLGLAR	823.46639	1	2	2	0.208
11	Pep-11	APRTPGGRR	966.54709	1	3	2	0.124
12	pep-12	APRLRFYS	1008.55047607422	0	0	0	0
13	Pep-14	pEPPGGSKVILF	1124.623	1	2	1	0.375
14	pep-15	PEKRPSQRSKYL	1487.82080078125	0	0	0	0
15	Pep-16	INLKALAALAKKIL	1478.99114	2	3	3	0.637
16	pep-17	Mastoparan from Polistes (Actually with -NH2)	1634.95080566406	0	0	0	0
17	pep-19	Apamin (Actually with -NH2)	2030.90185546875	0	0	0	0
18	pep-20	LRRDLDASREAKKQVEKALE	2354.30297851563	0	0	0	0
19	pep-24	HGQGTFTSDLSKQMEEEAVRLFIEWLKNGGPSSGAPPPS	4184.02734375	0	0	0	0
20	Pep-26	FLPLILGKLVKGLL	1523.02138	2	3	2	0.738
21	001|Brady2-9	Bradykinin Fragment 2-9, B1901 from Sigma	903.460266113281	0	0	0	0
22	002|des-Pro3,Ala2,6-Bradykinin	B4791 from Sigma	920.498046875	0	0	0	0
23	003|des-Pro2-Bradykinin	B2026 from Sigma	962.508605957031	0	0	0	0
24	004|Bradykinin	B3259 from Sigma	1059.56140136719	0	0	0	0
25	005|Tyr8-Bradykinin	B7885 from Sigma	1075.55627441406	0	0	0	0
26	006|Tyr-Bradykinin	B4764 from Sigma	1222.62475585938	0	0	0	0
27	007|I-S-Bradykinin	B1643 from Sigma	1259.67749023438	0	0	0	0
28	008|Fibrinopeptide_A	F3254 from Sigma	1535.68518066406	0	0	0	0
29	009|Tyr-C_peptide	C9781 from Sigma	3777.97607421875	0	0	0	0
30	010|Phe22_Endothelin1	Fragment 19-37, E9397 from Sigma	2181.13696289063	0	0	0	0
31	011|Osteocalcin	Fragment 7-19, O3632 from Sigma	1406.71936035156	0	0	0	0
32	012|Syntide_2	S2525 from Sigma	1506.92456054688	0	0	0	0
33	013|Leptin	Fragment 93-105, L7288 from Sigma	1526.80517578125	0	0	0	0
34	014|Ala92-Peptide_6	Fragment 84-103, P7967 from Sigma	2122.17578125	0	0	0	0
35	015|Pro_14_Arg	P2613 from Sigma	1532.85034179688	0	0	0	0
36	016|VIP-1-23	Vasoactive Intestinal Peptide Fragment 1-12, V0131 from Sigma	1424.63208007813	0	0	0	0
37	017|DBI-51-70	Diazepam Binding Inhibitor Fragment 51-70, human, G9898 from Sigma	2149.04736328125	0	0	0	0
38	018|EGF-661-681	Epidermal Growth Factor Receptor Fragment 661-681, E9520 from Sigma	2317.275390625	0	0	0	0
39	019|3X_FLAG_Peptide	F4799 from Sigma	2860.140625	0	0	0	0
40	020|PLSRTLSVAAKK	P5307 from Sigma	1269.77685546875	0	0	0	0
41	021|Dynorphin_A	Fragment 1-13, D7017 from Sigma	1602.9833984375	0	0	0	0
42	022|Neurotensin	N6383 from Sigma	1689.92016601563	0	0	0	0
43	023|Angiotensin_I	A9650 from Sigma	1295.67749023438	0	0	0	0
44	P001|ALBU_BOVIN	Serum Albumin Precursor.P02769	69225.421875	0	0	0	0
45	P002|CAH2_BOVIN	Carbonic anhydrase II (EC 4.2.1.1) - Bos taurus (Bovine).Q865Y7	29095.7109375	0	0	0	0
46	P003|LACB_BOVIN	Beta-lactoglobulin precursor (Beta-LG) (Allergen Bos d 5) - Bos taurus (Bovine).P02754	19870.267578125	0	0	0	0
47	P004|TRFE_BOVIN	Serotransferrin precursor (Transferrin) (Siderophilin) (Beta-1-metal binding globulin) - Bos taurus (Bovine).Q29443	77702.734375	0	0	0	0
48	P005|G3P_RABIT	Glyceraldehyde 3-phosphate dehydrogenase	35555.17	0	0	0	0
49	P006|BGAL_ECOLI	Beta-galactosidase (EC 3.2.1.23) (Lactase) - Escherichia coli.P00722	116278.0703125	0	0	0	0
50	P007|LCA_BOVIN	Alpha-lactalbumin precursor (Lactose synthase B protein) (Allergen Bos d 4) - Bos taurus (Bovine).P00711	16235.908203125	0	0	0	0
51	P008|MYG_HORSE	Myoglobin	16940.96	0	0	0	0
52	P009|OVAL_CHICK	Ovalbumin (Plakalbumin) (Allergen Gal d 2) (Gal d II) - Gallus gallus (Chicken).P01012	42722.4609375	0	0	0	0
53	P010|CYC_BOVIN	Cytochrome C	11565.02	0	0	0	0
54	P011|MANA_YEAST	Mannose-6-phosphate isomerase (EC 5.3.1.8) (Phosphomannose isomerase) (PMI) (Phosphohexomutase) - Saccharomyces cerevisiae (Baker's yeast).P29952	48027.28515625	0	0	0	0
55	P012|PHS2_RABIT	Glycogen phosphorylase, muscle form (EC 2.4.1.1) (Myophosphorylase) - Oryctolagus cuniculus (Rabbit).P00489	97096.8125	0	0	0	0
56	ADH1_YEAST	Alcohol dehydrogenase I	36799.66796875	0	0	0	0
57	DNASE1_BOVIN	deoxyribonuclease I (Bovine)	31325.728515625	0	0	0	0
58	P00330|ADH1_YEAST.t5.1	ANELLINVK	1012.5916423	1	2	2	0.2960591
59	P00330|ADH1_YEAST.t21.1	ANGTTVLVGMPAGAK	1385.7336141	1	3	2	0.2788896
60	P00330|ADH1_YEAST.t18.1	DIVGAVLK	813.4959614	1	2	1	0.2946748
61	P00330|ADH1_YEAST.t25.1	EALDFFAR	967.4762856	1	2	2	0.3387677
62	P00330|ADH1_YEAST.t17.2	EKDIVGAVLK	1070.6335043	1	2	2	0.2934074
63	P00330|ADH1_YEAST.t2.1	GVIFYESHGK	1135.5661551	1	2	2	0.2786604
64	P00330|ADH1_YEAST.t9.1	IGDYAGIK	835.4439275	1	2	2	0.2432967
65	P00330|ADH1_YEAST.t7.1	LPLVGGHEGAGVVVGMGENVK	2018.0617935	3	3	3	0.3647319
66	P00330|ADH1_YEAST.t16.1	SIGGEVFIDFTK	1311.6710059	2	2	2	0.3998586
67	P00330|ADH1_YEAST.t23.1	SISIVGSYVGNR	1250.6618361	2	2	2	0.2944126
68	P00330|ADH1_YEAST.t14.1	VLGIDGGEGK	943.4974124	1	2	2	0.2467773
69	P00330|ADH1_YEAST.t14.2	VLGIDGGEGKEELFR	1617.8361551	2	2	2	0.330697
70	P00330|ADH1_YEAST.t28.1	VVGLSTLPEIYEK	1446.7969259	2	3	2	0.3368339
71	P00330|ADH1_YEAST.t31.1	YVVDTSK	810.4122948	1	2	1	0.1981596
72	P00330|ADH1_YEAST.t19.1	ATDGGAHGVINVSVSEAAIEASTR	2311.1402983	2	3	3	0.3750517
\.


--
-- PostgreSQL database dump complete
--

