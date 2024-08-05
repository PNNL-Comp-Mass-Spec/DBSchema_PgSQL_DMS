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
-- Data for Name: t_unimod_bricks; Type: TABLE DATA; Schema: ont; Owner: d3l243
--

COPY ont.t_unimod_bricks (name, full_name, mono_mass, avg_mass, composition) FROM stdin;
Cr	Chromium	51.94051	51.9961	Cr
Cu	Copper	62.9296	63.546	Cu
dHex	Deoxy-hexose	146.0579	146.1412	C(6) H(10) O(4)
F	Fluorine	18.9984	18.9984	F
Fe	Iron	55.93494	55.845	Fe
H	Hydrogen	1.007825	1.00794	H
Hep	Heptose	192.0634	192.1666	C(7) H(12) O(6)
Hex	Hexose	162.0528	162.1406	H(10) C(6) O(5)
HexA	Hexuronic acid	176.0321	176.1241	C(6) H(8) O(6)
HexN	Hexosamine	161.0688	161.1558	H(11) C(6) O(4) N
HexNAc	N-Acetyl Hexosamine	203.0794	203.1925	C(8) H(13) N O(5)
Hg	Mercury	201.9706	200.59	Hg
I	Iodine	126.9045	126.9045	I
K	Potassium	38.96371	39.0983	K
Kdn	3-deoxy-d-glycero-D-galacto-nonulosonic acid	250.0689	250.2027	C(9) H(14) O(8)
Kdo	2-keto-3-deoxyoctulosonic acid	220.0583	220.1767	C(8) H(12) O(7)
Li	Lithium	7.016003	6.941	Li
Me	Methyl	14.01565	14.02658	C H(2)
Mg	Magnesium	23.98504	24.305	Mg
Mn	Manganese	54.93805	54.93805	Mn
Mo	Molybdenum	97.90541	95.94	Mo
N	Nitrogen	14.00307	14.0067	N
Na	Sodium	22.98977	22.98977	Na
NeuAc	N-acetyl neuraminic acid	291.0954	291.2546	C(11) H(17) N O(8)
NeuGc	N-glycoyl neuraminic acid	307.0903	307.254	C(11) H(17) N O(9)
Ni	Nickel	57.93534	58.6934	Ni
O	Oxygen	15.99492	15.9994	O
P	Phosphorous	30.97376	30.97376	P
Pd	Palladium	105.9035	106.42	Pd
Pent	Pentose	132.0423	132.1146	C(5) H(8) O(4)
Phos	Phosphate	79.96633	79.9799	H P O(3)
S	Sulphur	31.97207	32.065	S
Se	Selenium	79.91652	78.96	Se
Sulf	Sulfate	79.95682	80.0632	S O(3)
Water	Water	18.01056	18.01528	H(2) O
Zn	Zinc	63.92915	65.409	Zn
-		0	0	
13C	Carbon 13	13.00336	13.00336	13C
15N	Nitrogen 15	15.00011	15.00011	15N
18O	Oxygen 18	17.99916	17.99916	18O
2H	Deuterium	2.014102	2.014102	2H
Ac	Acetate	42.01056	42.03668	C(2) H(2) O
Ag	Silver	106.9051	107.8682	Ag
As	Arsenic	74.92159	74.92159	As
Au	Gold	196.9665	196.9666	Au
B	Boron	11.00931	10.811	B
Br	Bromine	78.91833	79.904	Br
C	Carbon	12	12.0107	C
Ca	Calcium	39.96259	40.078	Ca
Cd	Cadmium	113.9034	112.411	Cd
Cl	Chlorine	34.96885	35.453	Cl
Co	Cobalt	58.9332	58.93319	Co
\.


--
-- PostgreSQL database dump complete
--

