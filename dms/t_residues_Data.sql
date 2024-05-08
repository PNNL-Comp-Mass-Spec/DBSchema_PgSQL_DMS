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
-- Data for Name: t_residues; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_residues (residue_id, residue_symbol, description, abbreviation, average_mass, monoisotopic_mass, num_c, num_h, num_n, num_o, num_s, empirical_formula, amino_acid_name) FROM stdin;
1	-	No Symbol	No Symbol	0	0	0	0	0	0	0		
1024	<	N-Terminal Peptide	NTermPep	0	0	0	0	0	0	0		
1025	>	C-Terminal Peptide	CTermPep	0	0	0	0	0	0	0		
1026	[	N-Terminal Protein	NTermProt	0	0	0	0	0	0	0		
1027	]	C-Terminal Protein	CTermProt	0	0	0	0	0	0	0		
1000	A	Ala	Ala	71.0792940261929	71.0371100902557	3	5	1	1	0	C3 H5 N O	Alanine
1004	C	Cys	Cys	103.143682753682	103.009180784225	3	5	1	1	1	C3 H5 N O S	Cysteine
1005	E	Glu	Glu	129.116199871857	129.042587518692	5	7	1	3	0	C5 H7 N O3	Glutamic acid
1014	F	Phe	Phe	147.177838231808	147.068408727646	9	9	1	1	0	C9 H9 N O	Phenylalanine
1008	G	Gly	Gly	57.0522358907575	57.0214607715607	2	3	1	1	0	C2 H3 N O	Glycine
1009	H	His	His	137.142015793981	137.058904886246	6	7	3	1	0	C6 H7 N3 O	Histidine
1010	I	Ile	Ile	113.160468432499	113.084058046341	6	11	1	1	0	C6 H11 N O	Isoleucine
1031	J	Jjj	Jjj	113.1604	113.084	6	11	1	1	0	C6 H11 N O	\N
1012	K	Lys	Lys	128.175168840864	128.094955444336	6	12	2	1	0	C6 H12 N2 O	Lysine
1011	L	Leu	Leu	113.160468432499	113.084058046341	6	11	1	1	0	C6 H11 N O	Leucine
1013	M	Met	Met	131.197799024553	131.040479421616	5	9	1	1	1	C5 H9 N O S	Methionine
1002	N	Asn	Asn	114.104471781515	114.042921543121	4	6	2	2	0	C4 H6 N2 O2	Asparagine
1006	O	Orn	Orn	114.148110705429	114.079306125641	5	10	2	1	0	C5 H10 N2 O	Ornithine
1016	P	Pro	Pro	97.1174591453144	97.0527594089508	5	7	1	1	0	C5 H7 N O	Proline
1022	Q	Gln	Gln	128.13152991695	128.058570861816	5	8	2	2	0	C5 H8 N2 O2	Glutamine
1001	R	Arg	Arg	156.188618505844	156.101100921631	6	12	4	1	0	C6 H12 N4 O	Arginine
1017	S	Ser	Ser	87.0786643894641	87.0320241451263	3	5	1	2	0	C3 H5 N O2	Serine
1018	T	Thr	Thr	101.1057225249	101.047673463821	4	7	1	2	0	C4 H7 N O2	Threonine
1028	U	Sec (C3H5NOSe)	Sec	150.03794	150.95363	3	5	1	1	0	C3 H5 N O Se	Selenocysteine
1021	V	Val	Val	99.1334102970637	99.0684087276459	5	9	1	1	0	C5 H9 N O	Valine
1019	W	Trp	Trp	186.214752607545	186.079306125641	11	10	2	1	0	C11 H10 N2 O	Tryptophan
1023	X	Leu/Ile	Leu/Ile	113.160468432499	113.084058046341	6	11	1	1	0	C6 H11 N O	Leucine or Isoleucine
1020	Y	Tyr	Tyr	163.177208595079	163.063322782516	9	9	1	2	0	C9 H9 N O2	Tyrosine
1003	D	Asp	Asp	115.089141736421	115.026938199997	4	5	1	3	0	C4 H5 N O3	Aspartic acid
1007	B	Asn/Asp	Asn/Asp	114.104471781515	114.042921543121	4	6	2	2	0	C4 H6 N2 O2	Asparagine or Aspartic acid
1015	Z	Gln/Glu	Gln/Glu	128.13152991695	128.058570861816	5	8	2	2	0	C5 H8 N2 O2	Glutamine or Glutamic acid
\.


--
-- Name: t_residues_residue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_residues_residue_id_seq', 1031, true);


--
-- PostgreSQL database dump complete
--

