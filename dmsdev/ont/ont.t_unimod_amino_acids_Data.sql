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
-- Data for Name: t_unimod_amino_acids; Type: TABLE DATA; Schema: ont; Owner: d3l243
--

COPY ont.t_unimod_amino_acids (name, full_name, mono_mass, avg_mass, composition, three_letter) FROM stdin;
-		0	0		
A	Alanine	71.03712	71.0779	H(5) C(3) N O	Ala
C	Cysteine	103.0092	103.1429	H(5) C(3) N O S	Cys
C-term	C-term	17.00274	17.0073	H O	C-term
D	Aspartic acid	115.0269	115.0874	H(5) C(4) N O(3)	Asp
E	Glutamic acid	129.0426	129.114	H(7) C(5) N O(3)	Glu
F	Phenylalanine	147.0684	147.1739	H(9) C(9) N O	Phe
G	Glycine	57.02147	57.0513	H(3) C(2) N O	Gly
H	Histidine	137.0589	137.1393	H(7) C(6) N(3) O	His
I	Isoleucine	113.0841	113.1576	H(11) C(6) N O	Ile
K	Lysine	128.095	128.1723	H(12) C(6) N(2) O	Lys
L	Leucine	113.0841	113.1576	H(11) C(6) N O	Leu
M	Methionine	131.0405	131.1961	H(9) C(5) N O S	Met
N	Asparagine	114.0429	114.1026	H(6) C(4) N(2) O(2)	Asn
N-term	N-term	1.007825	1.0079	H	N-term
P	Proline	97.05276	97.1152	H(7) C(5) N O	Pro
Q	Glutamine	128.0586	128.1292	H(8) C(5) N(2) O(2)	Gln
R	Arginine	156.1011	156.1857	H(12) C(6) N(4) O	Arg
S	Serine	87.03203	87.0773	H(5) C(3) N O(2)	Ser
T	Threonine	101.0477	101.1039	H(7) C(4) N O(2)	Thr
U	Selenocysteine	150.9536	150.0379	H(5) C(3) N O Se	Sec
V	Valine	99.06841	99.1311	H(9) C(5) N O	Val
W	Tryptophan	186.0793	186.2099	H(10) C(11) N(2) O	Trp
Y	Tyrosine	163.0633	163.1733	H(9) C(9) N O(2)	Tyr
\.


--
-- PostgreSQL database dump complete
--

