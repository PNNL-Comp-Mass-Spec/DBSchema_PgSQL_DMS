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
-- Data for Name: t_aux_info_allowed_values; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_aux_info_allowed_values (aux_description_id, value) FROM stdin;
60	N14 Labeled
60	N15 Labeled
69	Late Log
69	Mid Log
69	Steady State
76	Dry Weight
76	Equal Concentration
76	Wet Weight
79	0.1 zirconia/silica
79	glass
84	lysosyme
97	HIC
97	HILIC
97	SAX
97	SCX
97	SEC
102	carbonate
102	Guanidine HCL
102	sodium
102	thiourea
102	urea
105	ethanol
105	Methanol
105	n-propanol
105	TFE
108	Chaps
108	Rapigest
108	SDS
108	Triton-X
111	DTT
111	Imm. TCEP
111	TBP
111	TCEP
116	ICAT
116	O18
116	PEO/Biotin
116	PhIAT
117	Ammonium Bicarbonate (NH4HCO3)
117	Trizma
120	10X dilution w/Buffer
120	G-25
120	PD-10
121	arg-N
121	Imm. Trypsin
121	lys-C
121	Trypsin
124	No
124	Yes
125	C-18
125	SCX
128	Cellulose
128	float-a-lyzer
128	slide-a-lyzer
130	No
130	Yes
139	A:0.1%Formic acid, balance water/B: 90%Acetonitrile, 0.1%Formic acid, balance water
139	A:0.2%HOAc, 0.05%TFA, balance water/B:90%Acetonitrile, 0.05%TFA, balance water
140	C-5-Jupiter
140	C18-Jupiter
142	Agilent
142	Isco
142	Shmidazu
144	150 uM
144	50 uM
149	Performic Acid
164	300 uM
167	Program
167	User
170	cell number
170	dry weight
170	volume
170	wet weight
200	Phenomenex, JUPITER RP C18, 250x2.0 mm (5um 300 angstrom)
200	Phenomenex, JUPITER RP C18, 250x4.6 mm (5um 300 angstrom)
200	PolyLC, PolySULFOETHYL A, 200x2.1 mm (5um 300 angstrom)
200	PolyLC, PolySULFOETHYL A, 200x4.6 mm (5um 300 angstrom)
200	PolyLC, PolySULFOETHYL A, 35x2.1 mm (3um 300 angstrom)
200	Waters, XBridge, 4.6X250mm, 5 um, 135A
201	0.05% TFA, 0.2% HOAc in H2O
201	10 mM Ammonium Formate, pH 3.0; 25% ACN
202	0.1% TFA, 90% ACN
202	500 mM Ammonium Formate, pH 6.8; 25% ACN
226	HIC
226	HILIC
226	IgY-12
226	IgY-14
226	IgY-R7
226	MARS-Human
226	MARS-Mouse
226	SAX
226	SCX
226	SEC
226	SuperMix
226	Supermix-Human
226	Supermix-Mouse
262	No
262	Yes
263	No
263	Yes
\.


--
-- PostgreSQL database dump complete
--

