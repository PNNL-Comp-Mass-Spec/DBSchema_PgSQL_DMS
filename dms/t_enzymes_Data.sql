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
-- Data for Name: t_enzymes; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_enzymes (enzyme_id, enzyme_name, description, p1, p1_exception, p2, p2_exception, cleavage_method, cleavage_offset, sequest_enzyme_index, protein_collection_name, comment) FROM stdin;
0	na	Not a real value	na	na	na	na	na	0	\N		\N
1	No_Enzyme	no digestive enzyme was used	na	na	na	na	na	0	0	HumanContam	\N
10	Trypsin	Standard tryptic digest	KR-	na	KR-	na	Standard	1	1	Tryp_Pig_Bov	\N
11	GluC	Endoproteinase GluC (aka V8)	ED-	na	ED-	na	Standard	1	12	HumanContam	\N
12	LysC	Endoproteinase LysC	K-	na	K-	na	Standard	1	13	HumanContam	\N
13	CnBR	Cyanogen Bromide	M-	na	M-	na	Standard	1	6	HumanContam	\N
14	Proteinase_K	Proteinase K	GAVLIMCFW-	na	GAVLIMCFWW-	na	Standard	1	15	HumanContam	\N
15	Trypsin_K	Trypsin, after K only	K-	P	K-	P	Standard	1	10	Tryp_Pig_Bov	\N
16	Elastase/Tryp/Chymo	Elastase, Trypsin, & Chymotrypsin	ALIVKRWFY-	P	ALIVKRWFY-	P	Standard	1	16	Tryp_Pig_Bov	\N
17	Trypsin_Modified	Modified Trypsin	KRLNH-	na	KRLNH-	na	Standard	1	2	Tryp_Pig_Bov	\N
18	AspN	AspN	D-	na	D-	na	Standard	0	14	HumanContam	\N
19	Trypsin_R	Trypsin, after R only aka ArgC	R-	P	R-	P	Standard	1	11	Tryp_Pig_Bov	\N
20	Chymotrypsin	Chymotrypsin	FWYL-	na	FWYL-	na	Standard	1	3	HumanContam	\N
21	ArgC	Endoproteinase ArgC	R-	na	R-	na	Standard	1	17	HumanContam	\N
22	Do_not_cleave	No cleavage anywhere; used when .Fasta is peptides, not proteins	B	na	B	na	Standard	1	18	HumanContam	\N
23	LysN	LysN metalloendopeptidase	K-	na	K-	na	Standard	0	19	HumanContam	\N
24	Pepsin	Pepsin	FLWY	na	FLWY	na	Standard	1	\N	HumanContam	Promega Pepsin, Cleaves at the C-Terminus of Phe, Leu, Tyr, Trp; https://www.promega.com/products/mass-spectrometry/proteases-and-surfactants/pepsin/?catNum=V1959
25	Elastase	Elastase	AVSGLI	na	AVSGLI	na	Standard	1	\N	HumanContam	Promega Elastase, Cleaves at C-Terminus of Ala, Val, Ser, Gly, Leu and Ile; https://www.promega.com/products/mass-spectrometry/proteases-and-surfactants/elastase/?catNum=V1891
26	LysC_plus_Trypsin	LysC and Trypsin; cleave after K or R if not followed by P, or cleave after K	KR-	na	KR-	na	Standard	1	\N	Tryp_Pig_Bov	\N
27	TrypN	LysargiNase; cleave before K or R, including if preceded by P	KR	na	KR	na	Standard	0	\N	Tryp_Pig_Bov	\N
28	Trypsin_plus_Chymotrypsin	Trypsin and Chymotrypsin	KRFWYL-	na	KRFWYL-	na	Standard	1	\N	Tryp_Pig_Bov	\N
29	Trypsin_plus_GluC	Trypsin and Endoproteinas GluC	KRED-	na	KRED-	na	Standard	1	\N	Tryp_Pig_Bov	\N
30	ALP	Alpha-Lytic Protease	TASV	na	TASV	na	Standard	1	\N	HumanContam	\N
31	Collagenase_III	Collagenase III	GLI	na	GLI	na	Standard	1	\N	Tryp_Pig_Bov	\N
\.


--
-- Name: t_enzymes_enzyme_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_enzymes_enzyme_id_seq', 31, true);


--
-- PostgreSQL database dump complete
--

