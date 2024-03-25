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
-- Data for Name: t_maxquant_mods; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_maxquant_mods (mod_id, mod_title, mod_position, mass_correction_id, composition, isobaric_mod_ion_number) FROM stdin;
41	DimethLys0	anywhere	1208	H(4) C(2)	0
42	DimethNter0	anyNterm	1208	H(4) C(2)	0
43	DimethLys4	anywhere	\N	Hx(4) C(2)	0
44	DimethNter4	anyNterm	\N	Hx(4) C(2)	0
45	DimethLys8	anywhere	\N	Hx(6) H(-2) Cx(2)	0
46	DimethNter8	anyNterm	\N	Hx(6) H(-2) Cx(2)	0
47	18O	anyCterm	\N	Ox(2) O(-2)	0
48	ICAT-0	anywhere	1041	H(17) C(10) N(3) O(3)	0
49	ICAT-9	anywhere	\N	H(17) Cx(9) N(3) O(3) C	0
50	ICPL-Lys0	anywhere	\N	H(3) C(6) N O	0
51	ICPL-Nter0	anyNterm	\N	H(3) C(6) N O	0
52	ICPL-Lys4	anywhere	\N	H(-1) Hx(4) C(6) N O	0
53	ICPL-Nter4	anyNterm	\N	H(-1) Hx(4) C(6) N O	0
54	ICPL-Lys6	anywhere	\N	H(3) Cx(6) N O	0
55	ICPL-Nter6	anyNterm	\N	H(3) Cx(6) N O	0
56	ICPL-Lys10	anywhere	\N	H(-1) Hx(4) Cx(6) N O	0
57	ICPL-Nter10	anyNterm	\N	H(-1) Hx(4) Cx(6) N O	0
58	mTRAQ-Lys0	anywhere	\N	H(12) C(7) N(2) O	0
59	mTRAQ-Nter0	anyNterm	\N	H(12) C(7) N(2) O	0
60	mTRAQ-Lys4	anywhere	\N	H(12) C(4) Cx(3) N Nx O	0
61	mTRAQ-Nter4	anyNterm	\N	H(12) C(4) Cx(3) N Nx O	0
62	mTRAQ-Lys8	anywhere	\N	H(12) C Cx(6) Nx(2) O	0
63	mTRAQ-Nter8	anyNterm	\N	H(12) C Cx(6) Nx(2) O	0
64	DimethLys2	anywhere	\N	H(2) Hx(2) C(2)	0
65	DimethNter2	anyNterm	\N	H(2) Hx(2) C(2)	0
66	DimethLys6	anywhere	\N	Hx(6) C(2) H(-2)	0
67	DimethNter6	anyNterm	\N	Hx(6) C(2) H(-2)	0
68	Leu7	anywhere	\N	C(-6) Cx(6) N(-1) Nx	0
69	Ile7	anywhere	\N	C(-6) Cx(6) N(-1) Nx	0
70	iTRAQ4plex-Nter114	anyNterm	1179	H(12) C(5) Cx(2) N(2) Ox	1
71	iTRAQ4plex-Nter115	anyNterm	1179	H(12) C(6) Cx N Ox Nx	2
72	iTRAQ4plex-Nter116	anyNterm	1179	H(12) C(4) Cx(3) N Nx O	3
73	iTRAQ4plex-Nter117	anyNterm	1179	H(12) C(4) Cx(3) N Nx O	4
74	iTRAQ4plex-Lys114	anywhere	1179	H(12) C(5) Cx(2) N(2) Ox	1
75	iTRAQ4plex-Lys115	anywhere	1179	H(12) C(6) Cx N Ox Nx	2
76	iTRAQ4plex-Lys116	anywhere	1179	H(12) C(4) Cx(3) N Nx O	3
77	iTRAQ4plex-Lys117	anywhere	1179	H(12) C(4) Cx(3) N Nx O	4
78	iTRAQ8plex-Nter113	anyNterm	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	1
79	iTRAQ8plex-Nter114	anyNterm	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	2
80	iTRAQ8plex-Nter115	anyNterm	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	3
81	iTRAQ8plex-Nter116	anyNterm	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	4
82	iTRAQ8plex-Nter117	anyNterm	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	5
83	iTRAQ8plex-Nter118	anyNterm	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	6
84	iTRAQ8plex-Nter119	anyNterm	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	7
85	iTRAQ8plex-Nter121	anyNterm	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	8
86	iTRAQ8plex-Lys113	anywhere	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	1
87	iTRAQ8plex-Lys114	anywhere	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	2
88	iTRAQ8plex-Lys115	anywhere	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	3
89	iTRAQ8plex-Lys116	anywhere	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	4
90	iTRAQ8plex-Lys117	anywhere	1237	H(24) C(7) Cx(7) N(3) Nx O(3)	5
91	iTRAQ8plex-Lys118	anywhere	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	6
92	iTRAQ8plex-Lys119	anywhere	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	7
93	iTRAQ8plex-Lys121	anywhere	1237	H(24) C(8) Cx(6) N(2) Nx(2) O(3)	8
94	TMT2plex-Nter126	anyNterm	1489	H(20) C(11) Cx N(2) O(2)	1
95	TMT2plex-Nter127	anyNterm	1489	H(20) C(11) Cx N(2) O(2)	2
96	TMT2plex-Lys126	anywhere	1489	H(20) C(11) Cx N(2) O(2)	1
97	TMT2plex-Lys127	anywhere	1489	H(20) C(11) Cx N(2) O(2)	2
98	TMT6plex-Nter126	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	1
99	TMT6plex-Nter127	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	2
100	TMT6plex-Nter128	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	3
101	TMT6plex-Nter129	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	4
102	TMT6plex-Nter130	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	5
103	TMT6plex-Nter131	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	6
104	TMT8plex-Nter126C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	1
105	TMT8plex-Nter127N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	2
106	TMT8plex-Nter127C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	3
107	TMT8plex-Nter128C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	4
108	TMT8plex-Nter129N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	5
109	TMT8plex-Nter129C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	6
110	TMT8plex-Nter130C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	7
111	TMT8plex-Nter131N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	8
112	TMT10plex-Nter126C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	1
113	TMT10plex-Nter127N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	2
114	TMT10plex-Nter127C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	3
115	TMT10plex-Nter128N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	4
116	TMT10plex-Nter128C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	5
117	TMT10plex-Nter129N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	6
118	TMT10plex-Nter129C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	7
119	TMT10plex-Nter130N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	8
120	TMT10plex-Nter130C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	9
121	TMT10plex-Nter131N	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	10
122	TMT11plex-Nter131C	anyNterm	1267	H(20) C(8) Cx(4) N O(2) Nx	11
123	TMT6plex-Lys126	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	1
124	TMT6plex-Lys127	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	2
125	TMT6plex-Lys128	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	3
126	TMT6plex-Lys129	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	4
127	TMT6plex-Lys130	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	5
128	TMT6plex-Lys131	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	6
129	TMT8plex-Lys126C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	1
130	TMT8plex-Lys127N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	2
131	TMT8plex-Lys127C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	3
132	TMT8plex-Lys128C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	4
133	TMT8plex-Lys129N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	5
134	TMT8plex-Lys129C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	6
135	TMT8plex-Lys130C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	7
136	TMT8plex-Lys131N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	8
137	TMT10plex-Lys126C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	1
138	TMT10plex-Lys127N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	2
139	TMT10plex-Lys127C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	3
140	TMT10plex-Lys128N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	4
141	TMT10plex-Lys128C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	5
142	TMT10plex-Lys129N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	6
143	TMT10plex-Lys129C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	7
144	TMT10plex-Lys130N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	8
145	TMT10plex-Lys130C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	9
146	TMT10plex-Lys131N	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	10
147	TMT11plex-Lys131C	anywhere	1267	H(20) C(8) Cx(4) N O(2) Nx	11
148	iodoTMT6plex-Cys126	anywhere	\N	H(28) C(12) Cx(4) N(3) Nx O(3)	1
149	iodoTMT6plex-Cys127	anywhere	\N	H(28) C(12) Cx(4) N(3) Nx O(3)	2
150	iodoTMT6plex-Cys128	anywhere	\N	H(28) C(12) Cx(4) N(3) Nx O(3)	3
151	iodoTMT6plex-Cys129	anywhere	\N	H(28) C(12) Cx(4) N(3) Nx O(3)	4
152	iodoTMT6plex-Cys130	anywhere	\N	H(28) C(12) Cx(4) N(3) Nx O(3)	5
153	iodoTMT6plex-Cys131	anywhere	\N	H(28) C(12) Cx(4) N(3) Nx O(3)	6
154	HexNAc (ST)	anywhere	1053	H(13) C(8) N O(5)	0
155	Hex(1)HexNAc(1) (ST)	anywhere	\N	C(14) H(23) O(10) N	0
156	Hex (K)	anywhere	1054	C(6) H(10) O(5)	0
157	Hex(5) HexNAc(4) NeuAc(2) (N)	anywhere	\N	C(84) H(136) O(61) N(6)	0
158	Hex(5) HexNAc(4) NeuAc(2) Sodium (N)	anywhere	\N	C(84) H(135) O(61) N(6) Na	0
159	Ala->Arg	anywhere	\N	H(7) C(3) N(3)	0
160	Ala->Asn	anywhere	1037	H C N O	0
161	Ala->Asp	anywhere	1417	C O(2)	0
162	Ala->Cys	anywhere	1220	S	0
163	Ala->Gln	anywhere	1014	H(3) C(2) N O	0
164	Ala->Glu	anywhere	\N	H(2) C(2) O(2)	0
165	Ala->Gly	anywhere	1270	H(-2) C(-1)	0
166	Ala->His	anywhere	\N	H(2) C(3) N(2)	0
167	Ala->Xle	anywhere	1188	H(6) C(3)	0
168	Ala->Lys	anywhere	\N	H(7) C(3) N	0
169	Ala->Met	anywhere	\N	H(4) C(2) S	0
170	Ala->Phe	anywhere	\N	H(4) C(6)	0
171	Ala->Pro	anywhere	\N	H(2) C(2)	0
172	Ala->Ser	anywhere	1115	O	0
173	Ala->Thr	anywhere	\N	H(2) C O	0
174	Ala->Trp	anywhere	\N	H(5) C(8) N	0
175	Ala->Tyr	anywhere	\N	H(4) C(6) O	0
176	Ala->Val	anywhere	1208	H(4) C(2)	0
177	Arg->Ala	anywhere	\N	H(-7) C(-3) N(-3)	0
178	Arg->Asn	anywhere	\N	H(-6) C(-2) N(-2) O	0
179	Arg->Asp	anywhere	\N	H(-7) C(-2) N(-3) O(2)	0
180	Arg->Cys	anywhere	\N	H(-7) C(-3) N(-3) S	0
181	Arg->Gln	anywhere	\N	H(-4) C(-1) N(-2) O	0
182	Arg->Glu	anywhere	\N	H(-5) C(-1) N(-3) O(2)	0
183	Arg->Gly	anywhere	\N	H(-9) C(-4) N(-3)	0
184	Arg->His	anywhere	\N	H(-5) N(-1)	0
185	Arg->Lys	anywhere	1498	N(-2)	0
186	Arg->Met	anywhere	\N	H(-3) C(-1) N(-3) S	0
187	Arg->Phe	anywhere	\N	H(-3) N(-3) C(3)	0
188	Arg->Pro	anywhere	\N	H(-5) C(-1) N(-3)	0
189	Arg->Ser	anywhere	\N	H(-7) C(-3) N(-3) O	0
190	Arg->Thr	anywhere	\N	H(-5) C(-2) N(-3) O	0
191	Arg->Trp	anywhere	\N	H(-2) N(-2) C(5)	0
192	Arg->Tyr	anywhere	\N	H(-3) N(-3) C(3) O	0
193	Arg->Val	anywhere	\N	H(-3) C(-1) N(-3)	0
194	Arg->Xle	anywhere	\N	H(-1) N(-3)	0
195	Asn->Ala	anywhere	\N	H(-1) N(-1) C(-1) O(-1)	0
196	Asn->Arg	anywhere	\N	O(-1) H(6) C(2) N(2)	0
197	Asn->Asp	anywhere	1127	H(-1) N(-1) O	0
198	Asn->Cys	anywhere	\N	H(-1) N(-1) C(-1) O(-1) S	0
199	Asn->Gln	anywhere	1032	H(2) C	0
200	Asn->Glu	anywhere	\N	N(-1) H C O	0
201	Asn->Gly	anywhere	\N	H(-3) N(-1) C(-2) O(-1)	0
202	Asn->His	anywhere	\N	O(-1) H C(2) N	0
203	Asn->Lys	anywhere	\N	O(-1) H(6) C(2)	0
204	Asn->Met	anywhere	\N	N(-1) O(-1) H(3) C S	0
205	Asn->Phe	anywhere	\N	N(-1) O(-1) H(3) C(5)	0
206	Asn->Pro	anywhere	\N	N(-1) O(-1) H C	0
207	Asn->Ser	anywhere	\N	H(-1) N(-1) C(-1)	0
208	Asn->Thr	anywhere	\N	N(-1) H	0
209	Asn->Trp	anywhere	\N	O(-1) H(4) C(7)	0
210	Asn->Tyr	anywhere	\N	N(-1) H(3) C(5)	0
211	Asn->Val	anywhere	\N	N(-1) O(-1) H(3) C	0
212	Asn->Xle	anywhere	\N	N(-1) O(-1) H(5) C(2)	0
213	Asp->Ala	anywhere	\N	O(-2) C(-1)	0
214	Asp->Arg	anywhere	\N	O(-2) H(7) C(2) N(3)	0
215	Asp->Asn	anywhere	\N	O(-1) H N	0
216	Asp->Cys	anywhere	\N	O(-2) C(-1) S	0
217	Asp->Gln	anywhere	\N	O(-1) H(3) C N	0
218	Asp->Glu	anywhere	1032	H(2) C	0
219	Asp->Gly	anywhere	\N	O(-2) C(-2) H(-2)	0
220	Asp->His	anywhere	\N	O(-2) H(2) C(2) N(2)	0
221	Asp->Lys	anywhere	\N	O(-2) H(7) C(2) N	0
222	Asp->Met	anywhere	\N	O(-2) H(4) C S	0
223	Asp->Phe	anywhere	\N	O(-2) H(4) C(5)	0
224	Asp->Pro	anywhere	\N	O(-2) H(2) C	0
225	Asp->Ser	anywhere	\N	O(-1) C(-1)	0
226	Asp->Thr	anywhere	\N	O(-1) H(2)	0
227	Asp->Trp	anywhere	\N	O(-2) H(5) C(7) N	0
228	Asp->Tyr	anywhere	\N	O(-1) H(4) C(5)	0
229	Asp->Val	anywhere	\N	O(-2) H(4) C	0
230	Asp->Xle	anywhere	\N	O(-2) H(6) C(2)	0
231	Cys->Ala	anywhere	\N	S(-1)	0
232	Cys->Arg	anywhere	\N	S(-1) H(7) C(3) N(3)	0
233	Cys->Asn	anywhere	\N	S(-1) H C N O	0
234	Cys->Asp	anywhere	\N	S(-1) C O(2)	0
235	Cys->Gln	anywhere	\N	S(-1) H(3) C(2) N O	0
236	Cys->Glu	anywhere	\N	S(-1) H(2) C(2) O(2)	0
237	Cys->Gly	anywhere	\N	S(-1) H(-2) C(-1)	0
238	Cys->His	anywhere	\N	S(-1) H(2) C(3) N(2)	0
239	Cys->Lys	anywhere	\N	S(-1) H(7) C(3) N	0
240	Cys->Met	anywhere	1208	H(4) C(2)	0
241	Cys->Phe	anywhere	\N	S(-1) H(4) C(6)	0
242	Cys->Pro	anywhere	\N	S(-1) H(2) C(2)	0
243	Cys->Ser	anywhere	\N	S(-1) O	0
244	Cys->Thr	anywhere	\N	S(-1) H(2) C O	0
245	Cys->Trp	anywhere	\N	S(-1) H(5) C(8) N	0
246	Cys->Tyr	anywhere	\N	S(-1) H(4) C(6) O	0
247	Cys->Val	anywhere	\N	S(-1) H(4) C(2)	0
248	Cys->Xle	anywhere	\N	S(-1) H(6) C(3)	0
249	Gln->Ala	anywhere	\N	H(-3) C(-2) N(-1) O(-1)	0
250	Gln->Arg	anywhere	\N	O(-1) H(4) C N(2)	0
251	Gln->Asn	anywhere	1270	H(-2) C(-1)	0
252	Gln->Asp	anywhere	\N	H(-3) C(-1) N(-1) O	0
253	Gln->Cys	anywhere	\N	H(-3) C(-2) N(-1) O(-1) S	0
254	Gln->Glu	anywhere	1127	H(-1) N(-1) O	0
255	Gln->Gly	anywhere	\N	H(-5) C(-3) N(-1) O(-1)	0
256	Gln->His	anywhere	\N	H(-1) O(-1) C N	0
257	Gln->Lys	anywhere	\N	O(-1) H(4) C	0
258	Gln->Met	anywhere	\N	N(-1) O(-1) H S	0
259	Gln->Phe	anywhere	\N	N(-1) O(-1) H C(4)	0
260	Gln->Pro	anywhere	\N	H(-1) N(-1) O(-1)	0
261	Gln->Ser	anywhere	\N	H(-3) C(-2) N(-1)	0
262	Gln->Thr	anywhere	\N	H(-1) C(-1) N(-1)	0
263	Gln->Trp	anywhere	\N	O(-1) H(2) C(6)	0
264	Gln->Tyr	anywhere	\N	N(-1) H C(4)	0
265	Gln->Val	anywhere	\N	N(-1) O(-1) H	0
266	Gln->Xle	anywhere	\N	N(-1) O(-1) H(3) C	0
267	Glu->Ala	anywhere	\N	O(-2) H(-2) C(-2)	0
268	Glu->Arg	anywhere	\N	O(-2) H(5) C N(3)	0
269	Glu->Asn	anywhere	\N	O(-1) H(-1) C(-1) N	0
270	Glu->Asp	anywhere	1270	H(-2) C(-1)	0
271	Glu->Cys	anywhere	\N	O(-2) H(-2) C(-2) S	0
272	Glu->Gln	anywhere	\N	O(-1) H N	0
273	Glu->Gly	anywhere	\N	O(-2) H(-4) C(-3)	0
274	Glu->His	anywhere	\N	O(-2) C N(2)	0
275	Glu->Lys	anywhere	\N	O(-2) H(5) C N	0
276	Glu->Met	anywhere	\N	O(-2) H(2) S	0
277	Glu->Phe	anywhere	\N	O(-2) H(2) C(4)	0
278	Glu->Pro	anywhere	\N	O(-2)	0
279	Glu->Ser	anywhere	\N	O(-1) H(-2) C(-2)	0
280	Glu->Thr	anywhere	\N	O(-1) C(-1)	0
281	Glu->Trp	anywhere	\N	O(-2) H(3) C(6) N	0
282	Glu->Tyr	anywhere	\N	O(-1) H(2) C(4)	0
283	Glu->Val	anywhere	\N	O(-2) H(2)	0
284	Glu->Xle	anywhere	\N	O(-2) H(4) C	0
285	Gly->Ala	anywhere	1032	H(2) C	0
286	Gly->Arg	anywhere	\N	H(9) C(4) N(3)	0
287	Gly->Asn	anywhere	1014	H(3) C(2) N O	0
288	Gly->Asp	anywhere	\N	H(2) C(2) O(2)	0
289	Gly->Cys	anywhere	1252	H(2) C S	0
290	Gly->Gln	anywhere	1284	H(5) C(3) N O	0
291	Gly->Glu	anywhere	\N	H(4) C(3) O(2)	0
292	Gly->His	anywhere	\N	H(4) C(4) N(2)	0
293	Gly->Lys	anywhere	\N	H(9) C(4) N	0
294	Gly->Met	anywhere	\N	H(6) C(3) S	0
295	Gly->Phe	anywhere	\N	H(6) C(7)	0
296	Gly->Pro	anywhere	\N	H(4) C(3)	0
297	Gly->Ser	anywhere	\N	H(2) C O	0
298	Gly->Thr	anywhere	\N	H(4) C(2) O	0
299	Gly->Trp	anywhere	\N	H(7) C(9) N	0
300	Gly->Tyr	anywhere	\N	H(6) C(7) O	0
301	Gly->Val	anywhere	1188	H(6) C(3)	0
302	Gly->Xle	anywhere	\N	H(8) C(4)	0
303	His->Ala	anywhere	\N	H(-2) C(-3) N(-2)	0
304	His->Arg	anywhere	\N	H(5) N	0
305	His->Asn	anywhere	1234	H(-1) C(-2) N(-1) O	0
306	His->Asp	anywhere	1235	H(-2) C(-2) N(-2) O(2)	0
307	His->Cys	anywhere	\N	H(-2) C(-3) N(-2) S	0
308	His->Gln	anywhere	\N	C(-1) N(-1) H O	0
309	His->Glu	anywhere	1389	C(-1) N(-2) O(2)	0
310	His->Gly	anywhere	\N	H(-4) C(-4) N(-2)	0
311	His->Lys	anywhere	\N	N(-1) H(5)	0
312	His->Met	anywhere	\N	C(-1) N(-2) H(2) S	0
313	His->Phe	anywhere	\N	N(-2) H(2) C(3)	0
314	His->Pro	anywhere	\N	C(-1) N(-2)	0
315	His->Ser	anywhere	\N	H(-2) C(-3) N(-2) O	0
316	His->Thr	anywhere	\N	C(-2) N(-2) O	0
317	His->Trp	anywhere	\N	N(-1) H(3) C(5)	0
318	His->Tyr	anywhere	\N	N(-2) H(2) C(3) O	0
319	His->Val	anywhere	\N	C(-1) N(-2) H(2)	0
320	His->Xle	anywhere	\N	N(-2) H(4)	0
321	Lys->Ala	anywhere	\N	N(-1) H(-7) C(-3)	0
322	Lys->Arg	anywhere	\N	N(2)	0
323	Lys->Asn	anywhere	\N	H(-6) C(-2) O	0
324	Lys->Asp	anywhere	\N	N(-1) H(-7) C(-2) O(2)	0
325	Lys->Cys	anywhere	\N	N(-1) H(-7) C(-3) S	0
326	Lys->Gln	anywhere	\N	H(-4) C(-1) O	0
327	Lys->Glu	anywhere	\N	N(-1) H(-5) C(-1) O(2)	0
328	Lys->Gly	anywhere	\N	N(-1) H(-9) C(-4)	0
329	Lys->His	anywhere	\N	H(-5) N	0
330	Lys->Met	anywhere	\N	N(-1) H(-3) C(-1) S	0
331	Lys->Phe	anywhere	\N	N(-1) H(-3) C(3)	0
332	Lys->Pro	anywhere	\N	N(-1) H(-5) C(-1)	0
333	Lys->Ser	anywhere	\N	N(-1) H(-7) C(-3) O	0
334	Lys->Thr	anywhere	\N	N(-1) H(-5) C(-2) O	0
335	Lys->Trp	anywhere	\N	H(-2) C(5)	0
336	Lys->Tyr	anywhere	\N	N(-1) H(-3) C(3) O	0
337	Lys->Val	anywhere	\N	N(-1) H(-3) C(-1)	0
338	Lys->Xle	anywhere	\N	N(-1) H(-1)	0
339	Met->Ala	anywhere	\N	H(-4) C(-2) S(-1)	0
340	Met->Arg	anywhere	\N	S(-1) H(3) C N(3)	0
341	Met->Asn	anywhere	\N	H(-3) C(-1) S(-1) N O	0
342	Met->Asp	anywhere	\N	H(-4) C(-1) S(-1) O(2)	0
343	Met->Cys	anywhere	\N	H(-4) C(-2)	0
344	Met->Gln	anywhere	\N	H(-1) S(-1) N O	0
345	Met->Glu	anywhere	\N	H(-2) S(-1) O(2)	0
346	Met->Gly	anywhere	\N	H(-6) C(-3) S(-1)	0
347	Met->His	anywhere	\N	H(-2) S(-1) C N(2)	0
348	Met->Lys	anywhere	\N	S(-1) H(3) C N	0
349	Met->Phe	anywhere	\N	S(-1) C(4)	0
350	Met->Pro	anywhere	1340	H(-2) S(-1)	0
351	Met->Ser	anywhere	\N	H(-4) C(-2) S(-1) O	0
352	Met->Thr	anywhere	\N	H(-2) C(-1) S(-1) O	0
353	Met->Trp	anywhere	\N	S(-1) H C(6) N	0
354	Met->Tyr	anywhere	\N	S(-1) C(4) O	0
355	Met->Val	anywhere	\N	S(-1)	0
356	Met->Xle	anywhere	\N	S(-1) H(2) C	0
357	Phe->Ala	anywhere	\N	H(-4) C(-6)	0
358	Phe->Arg	anywhere	\N	C(-3) H(3) N(3)	0
359	Phe->Asn	anywhere	\N	H(-3) C(-5) N O	0
360	Phe->Asp	anywhere	\N	H(-4) C(-5) O(2)	0
361	Phe->Cys	anywhere	\N	H(-4) C(-6) S	0
362	Phe->Gln	anywhere	\N	H(-1) C(-4) N O	0
363	Phe->Glu	anywhere	\N	H(-2) C(-4) O(2)	0
364	Phe->Gly	anywhere	\N	H(-6) C(-7)	0
365	Phe->His	anywhere	\N	H(-2) C(-3) N(2)	0
366	Phe->Lys	anywhere	\N	C(-3) H(3) N	0
367	Phe->Met	anywhere	\N	C(-4) S	0
368	Phe->Pro	anywhere	\N	H(-2) C(-4)	0
369	Phe->Ser	anywhere	\N	H(-4) C(-6) O	0
370	Phe->Thr	anywhere	\N	H(-2) C(-5) O	0
371	Phe->Trp	anywhere	1266	H C(2) N	0
372	Phe->Tyr	anywhere	1115	O	0
373	Phe->Val	anywhere	\N	C(-4)	0
374	Phe->Xle	anywhere	\N	C(-3) H(2)	0
375	Pro->Ala	anywhere	\N	C(-2) H(-2)	0
376	Pro->Arg	anywhere	\N	H(5) C N(3)	0
377	Pro->Asn	anywhere	\N	C(-1) H(-1) N O	0
378	Pro->Asp	anywhere	\N	C(-1) H(-2) O(2)	0
379	Pro->Cys	anywhere	\N	C(-2) H(-2) S	0
380	Pro->Gln	anywhere	\N	H N O	0
381	Pro->Glu	anywhere	1064	O(2)	0
382	Pro->Gly	anywhere	\N	C(-3) H(-4)	0
383	Pro->His	anywhere	\N	C N(2)	0
384	Pro->Lys	anywhere	\N	H(5) C N	0
385	Pro->Met	anywhere	\N	H(2) S	0
386	Pro->Phe	anywhere	\N	C(4) H(2)	0
387	Pro->Ser	anywhere	\N	C(-2) H(-2) O	0
388	Pro->Thr	anywhere	1233	C(-1) O	0
389	Pro->Trp	anywhere	\N	C(6) H(3) N	0
390	Pro->Tyr	anywhere	\N	C(4) H(2) O	0
391	Pro->Val	anywhere	\N	H(2)	0
392	Pro->Xle	anywhere	\N	C H(4)	0
393	Ser->Ala	anywhere	\N	O(-1)	0
394	Ser->Arg	anywhere	\N	O(-1) H(7) C(3) N(3)	0
395	Ser->Asn	anywhere	1276	H C N	0
396	Ser->Asp	anywhere	\N	O C	0
397	Ser->Cys	anywhere	\N	O(-1) S	0
398	Ser->Gln	anywhere	\N	H(3) C(2) N	0
399	Ser->Glu	anywhere	\N	O H(2) C(2)	0
400	Ser->Gly	anywhere	\N	O(-1) H(-2) C(-1)	0
401	Ser->His	anywhere	\N	O(-1) H(2) C(3) N(2)	0
402	Ser->Lys	anywhere	\N	O(-1) H(7) C(3) N	0
403	Ser->Met	anywhere	\N	O(-1) H(4) C(2) S	0
404	Ser->Phe	anywhere	\N	O(-1) H(4) C(6)	0
405	Ser->Pro	anywhere	\N	O(-1) H(2) C(2)	0
406	Ser->Thr	anywhere	1032	H(2) C	0
407	Ser->Trp	anywhere	\N	O(-1) H(5) C(8) N	0
408	Ser->Tyr	anywhere	\N	H(4) C(6)	0
409	Ser->Val	anywhere	\N	O(-1) H(4) C(2)	0
410	Ser->Xle	anywhere	\N	O(-1) H(6) C(3)	0
411	Thr->Ala	anywhere	\N	O(-1) H(-2) C(-1)	0
412	Thr->Arg	anywhere	\N	O(-1) H(5) C(2) N(3)	0
413	Thr->Asn	anywhere	\N	H(-1) N	0
414	Thr->Asp	anywhere	1213	H(-2) O	0
415	Thr->Cys	anywhere	\N	O(-1) H(-2) C(-1) S	0
416	Thr->Gln	anywhere	1276	H C N	0
417	Thr->Glu	anywhere	\N	O C	0
418	Thr->Gly	anywhere	\N	O(-1) H(-4) C(-2)	0
419	Thr->His	anywhere	\N	O(-1) C(2) N(2)	0
420	Thr->Lys	anywhere	\N	O(-1) H(5) C(2) N	0
421	Thr->Met	anywhere	\N	O(-1) H(2) C S	0
422	Thr->Phe	anywhere	\N	O(-1) H(2) C(5)	0
423	Thr->Pro	anywhere	\N	O(-1) C	0
424	Thr->Ser	anywhere	1270	H(-2) C(-1)	0
425	Thr->Trp	anywhere	\N	O(-1) H(3) C(7) N	0
426	Thr->Tyr	anywhere	\N	H(2) C(5)	0
427	Thr->Val	anywhere	\N	O(-1) H(2) C	0
428	Thr->Xle	anywhere	\N	O(-1) H(4) C(2)	0
429	Trp->Ala	anywhere	\N	H(-5) C(-8) N(-1)	0
430	Trp->Arg	anywhere	\N	C(-5) H(2) N(2)	0
431	Trp->Asn	anywhere	\N	H(-4) C(-7) O	0
432	Trp->Asp	anywhere	\N	H(-5) C(-7) N(-1) O(2)	0
433	Trp->Cys	anywhere	\N	H(-5) C(-8) N(-1) S	0
434	Trp->Gln	anywhere	\N	H(-2) C(-6) O	0
435	Trp->Glu	anywhere	\N	H(-3) C(-6) N(-1) O(2)	0
436	Trp->Gly	anywhere	\N	H(-7) C(-9) N(-1)	0
437	Trp->His	anywhere	\N	H(-3) C(-5) N	0
438	Trp->Lys	anywhere	\N	C(-5) H(2)	0
439	Trp->Met	anywhere	\N	H(-1) C(-6) N(-1) S	0
440	Trp->Phe	anywhere	\N	H(-1) C(-2) N(-1)	0
441	Trp->Pro	anywhere	\N	H(-3) C(-6) N(-1)	0
442	Trp->Ser	anywhere	\N	H(-5) C(-8) N(-1) O	0
443	Trp->Thr	anywhere	\N	H(-3) C(-7) N(-1) O	0
444	Trp->Tyr	anywhere	1234	H(-1) C(-2) N(-1) O	0
445	Trp->Val	anywhere	\N	H(-1) C(-6) N(-1)	0
446	Trp->Xle	anywhere	\N	C(-5) N(-1) H	0
447	Tyr->Ala	anywhere	\N	C(-6) H(-4) O(-1)	0
448	Tyr->Arg	anywhere	\N	C(-3) O(-1) H(3) N(3)	0
449	Tyr->Asn	anywhere	\N	C(-5) H(-3) N	0
450	Tyr->Asp	anywhere	\N	C(-5) H(-4) O	0
451	Tyr->Cys	anywhere	\N	C(-6) H(-4) O(-1) S	0
452	Tyr->Gln	anywhere	\N	C(-4) H(-1) N	0
453	Tyr->Glu	anywhere	\N	C(-4) H(-2) O	0
454	Tyr->Gly	anywhere	\N	C(-7) H(-6) O(-1)	0
455	Tyr->His	anywhere	\N	C(-3) H(-2) O(-1) N(2)	0
456	Tyr->Lys	anywhere	\N	C(-3) O(-1) H(3) N	0
457	Tyr->Met	anywhere	\N	C(-4) O(-1) S	0
458	Tyr->Phe	anywhere	\N	O(-1)	0
459	Tyr->Pro	anywhere	\N	C(-4) H(-2) O(-1)	0
460	Tyr->Ser	anywhere	\N	C(-6) H(-4)	0
461	Tyr->Thr	anywhere	\N	C(-5) H(-2)	0
462	Tyr->Trp	anywhere	\N	O(-1) H C(2) N	0
10	Pro5	anywhere	\N	Cx(5) C(-5)	0
463	Tyr->Val	anywhere	\N	C(-4) O(-1)	0
464	Tyr->Xle	anywhere	\N	C(-3) O(-1) H(2)	0
465	Val->Ala	anywhere	\N	C(-2) H(-4)	0
466	Val->Arg	anywhere	\N	C H(3) N(3)	0
467	Val->Asn	anywhere	\N	C(-1) H(-3) N O	0
468	Val->Asp	anywhere	\N	C(-1) H(-4) O(2)	0
469	Val->Cys	anywhere	\N	C(-2) H(-4) S	0
470	Val->Gln	anywhere	1060	H(-1) N O	0
471	Val->Glu	anywhere	\N	H(-2) O(2)	0
472	Val->Gly	anywhere	\N	C(-3) H(-6)	0
473	Val->His	anywhere	\N	H(-2) C N(2)	0
474	Val->Lys	anywhere	\N	H(3) C N	0
475	Val->Met	anywhere	1220	S	0
476	Val->Phe	anywhere	\N	C(4)	0
477	Val->Pro	anywhere	1173	H(-2)	0
478	Val->Ser	anywhere	\N	C(-2) H(-4) O	0
479	Val->Thr	anywhere	\N	C(-1) H(-2) O	0
480	Val->Trp	anywhere	\N	H C(6) N	0
481	Val->Tyr	anywhere	\N	C(4) O	0
482	Val->Xle	anywhere	\N	C H(2)	0
483	Xle->Ala	anywhere	\N	C(-3) H(-6)	0
484	Xle->Arg	anywhere	\N	H N(3)	0
485	Xle->Asn	anywhere	\N	C(-2) H(-5) N O	0
486	Xle->Asp	anywhere	\N	C(-2) H(-6) O(2)	0
487	Xle->Cys	anywhere	\N	C(-3) H(-6) S	0
488	Xle->Gln	anywhere	\N	C(-1) H(-3) N O	0
489	Xle->Glu	anywhere	\N	C(-1) H(-4) O(2)	0
490	Xle->Gly	anywhere	\N	C(-4) H(-8)	0
491	Xle->His	anywhere	\N	H(-4) N(2)	0
492	Xle->Lys	anywhere	1170	H N	0
493	Xle->Met	anywhere	\N	C(-1) H(-2) S	0
494	Xle->Phe	anywhere	\N	H(-2) C(3)	0
495	Xle->Pro	anywhere	\N	C(-1) H(-4)	0
496	Xle->Ser	anywhere	\N	C(-3) H(-6) O	0
497	Xle->Thr	anywhere	\N	C(-2) H(-4) O	0
498	Xle->Trp	anywhere	\N	H(-1) C(5) N	0
499	Xle->Tyr	anywhere	\N	H(-2) C(3) O	0
500	Xle->Val	anywhere	\N	C(-1) H(-2)	0
501	CamCys->Ala	anywhere	\N	S(-1) H(-3) C(-2) N(-1) O(-1)	0
502	CamCys->Arg	anywhere	\N	S(-1) H(4) C N(2) O(-1)	0
503	CamCys->Asn	anywhere	\N	S(-1) H(-2) C(-1)	0
504	CamCys->Asp	anywhere	\N	S(-1) O H(-3) C(-1) N(-1)	0
505	CamCys->Gln	anywhere	\N	S(-1)	0
506	CamCys->Glu	anywhere	\N	S(-1) O H(-1) N(-1)	0
507	CamCys->Gly	anywhere	\N	S(-1) H(-5) C(-3) N(-1) O(-1)	0
508	CamCys->His	anywhere	\N	S(-1) C N H(-1) O(-1)	0
509	CamCys->Lys	anywhere	\N	S(-1) H(4) C O(-1)	0
510	CamCys->Met	anywhere	\N	H N(-1) O(-1)	0
511	CamCys->Phe	anywhere	\N	S(-1) H C(4) N(-1) O(-1)	0
512	CamCys->Pro	anywhere	\N	S(-1) H(-1) N(-1) O(-1)	0
513	CamCys->Ser	anywhere	\N	S(-1) H(-3) C(-2) N(-1)	0
514	CamCys->Thr	anywhere	\N	S(-1) H(-1) C(-1) N(-1)	0
515	CamCys->Trp	anywhere	\N	S(-1) H(3) C(6) O(-1)	0
516	CamCys->Tyr	anywhere	\N	S(-1) H C(4) N(-1)	0
517	CamCys->Val	anywhere	\N	S(-1) H N(-1) O(-1)	0
518	CamCys->Xle	anywhere	\N	S(-1) H(3) C N(-1) O(-1)	0
519	Ala->CamCys	anywhere	\N	S H(3) C(2) N O	0
520	Arg->CamCys	anywhere	\N	H(-4) C(-1) N(-2) S O	0
521	Asn->CamCys	anywhere	\N	S H(2) C	0
522	Asp->CamCys	anywhere	\N	O(-1) S H(3) C N	0
523	Gln->CamCys	anywhere	1220	S	0
524	Glu->CamCys	anywhere	\N	O(-1) S H N	0
525	Gly->CamCys	anywhere	\N	H(5) C(3) S N O	0
526	His->CamCys	anywhere	\N	C(-1) N(-1) S H O	0
527	Lys->CamCys	anywhere	\N	H(-4) C(-1) S O	0
528	Met->CamCys	anywhere	1060	H(-1) N O	0
529	Phe->CamCys	anywhere	\N	H(-1) C(-4) S N O	0
530	Pro->CamCys	anywhere	\N	S H N O	0
531	Ser->CamCys	anywhere	\N	S H(3) C(2) N	0
532	Thr->CamCys	anywhere	\N	S H C N	0
533	Trp->CamCys	anywhere	\N	H(-2) C(-6) S O	0
534	Tyr->CamCys	anywhere	\N	C(-4) H(-1) S N	0
535	Val->CamCys	anywhere	\N	H(-1) S N O	0
536	Xle->CamCys	anywhere	\N	C(-1) H(-3) S N O	0
537	Thioacyl (DSP)	anywhere	\N	C(3) H(4) O S	0
538	K2020	anywhere	\N	Cx(2) C(-2) Nx(2) N(-2)	0
539	K0400	anywhere	\N	Hx(4) H(-4)	0
540	K6020	anywhere	\N	Cx(6) C(-6) Nx(2) N(-2)	0
541	K5210	anywhere	\N	Cx(5) C(-5) Hx(2) H(-2) Nx(1) N(-1)	0
542	K3410	anywhere	\N	Cx(3) C(-3) Hx(4) H(-4) Nx N(-1)	0
543	K4400	anywhere	\N	Cx(4) C(-4) Hx(4) H(-4)	0
544	K0800	anywhere	\N	Hx(8) H(-8)	0
545	K6420	anywhere	\N	Cx(6) C(-6) Hx(4) H(-4) Nx(2) N(-2)	0
546	K1920	anywhere	\N	Cx(1) C(-1) Hx(9) H(-9) Nx(2) N(-2)	0
547	K3900	anywhere	\N	Cx(3) C(-3) Hx(9) H(-9)	0
548	Cysteinyl	anywhere	1312	H(5) C(3) N O(2) S	0
549	Cysteinyl - carbamidomethyl	anywhere	\N	H(2) O C S	0
550	Oxidation (MP)	anywhere	1115	O	0
551	TMTpro16plex-Nter126C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	1
552	TMTpro16plex-Nter127N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	2
553	TMTpro16plex-Nter127C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	3
554	TMTpro16plex-Nter128N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	4
555	TMTpro16plex-Nter128C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	5
556	TMTpro16plex-Nter129N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	6
557	TMTpro16plex-Nter129C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	7
558	TMTpro16plex-Nter130N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	8
559	TMTpro16plex-Nter130C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	9
560	TMTpro16plex-Nter131N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	10
561	TMTpro16plex-Nter131C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	11
562	TMTpro16plex-Nter132N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	12
563	TMTpro16plex-Nter132C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	13
564	TMTpro16plex-Nter133N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	14
565	TMTpro16plex-Nter133C	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	15
1	Acetyl (K)	notCterm	1120	C(2) H(2) O	0
2	Acetyl (Protein N-term)	proteinNterm	1120	C(2) H(2) O	0
3	Carbamidomethyl (C)	anywhere	1014	H(3) C(2) N O	0
4	Oxidation (M)	anywhere	1115	O	0
5	Phospho (STY)	anywhere	1010	H O(3) P	0
6	GlyGly (K)	anywhere	1021	H(6) C(4) N(2) O(2)	0
7	Methyl (KR)	anywhere	1032	H(2) C	0
8	Dimethyl (KR)	anywhere	1208	H(4) C(2)	0
9	Trimethyl (K)	anywhere	1188	H(6) C(3)	0
11	Pro6	anywhere	\N	Cx(5) Nx C(-5) N(-1)	0
12	Glu->pyro-Glu	anyNterm	1121	H(-2) O(-1)	0
13	Gln->pyro-Glu	anyNterm	1169	H(-3) N(-1)	0
14	QQTGG (K)	notCterm	\N	H(29) C(18) N(7) O(8)	0
15	Deamidation (N)	anywhere	1127	H(-1) N(-1) O	0
16	Deamidation 18O (N)	anywhere	\N	H(-1) N(-1) Ox	0
17	Deamidation (NQ)	anywhere	1127	H(-1) N(-1) O	0
18	Hydroxyproline	anywhere	1115	O	0
19	Carbamyl (N-term)	anyNterm	1037	H C N O	0
20	Delta:H(2)C(2) (N-term)	anyNterm	\N	C(2) H(2)	0
21	Dioxidation (MW)	anywhere	1064	O(2)	0
22	Trioxidation (C)	anywhere	1008	O(3)	0
23	Dethiomethyl (M)	anywhere	1161	H(-4) C(-1) S(-1)	0
24	Cation:Na (DE)	anywhere	\N	H(-1) Na	0
25	Methyl (E)	anywhere	1032	H(2) C	0
26	Dehydrated (ST)	anywhere	1121	H(-2) O(-1)	0
27	Oxidation (P)	anywhere	1115	O	0
28	Dimethyl (K)	anywhere	1208	H(4) C(2)	0
29	Amidated (Protein C-term)	proteinCterm	1243	H N O(-1)	0
30	Sulfo (STY)	anywhere	1220	S	0
31	Acetyl (N-term)	anyNterm	1120	C(2) H(2) O	0
32	Amidated (C-term)	anyCterm	1243	H N O(-1)	0
33	Sulfation (Y)	anywhere	\N	S O(3)	0
34	Phospho (ST)	anywhere	1010	H O(3) P	0
35	Cys-Cys	anywhere	1272	H(-1)	0
36	Arg6	anywhere	\N	Cx(6) C(-6)	0
37	Arg10	anywhere	1165	Cx(6) Nx(4) C(-6) N(-4)	0
38	Lys4	anywhere	\N	Hx(4) H(-4)	0
39	Lys6	anywhere	\N	Cx(6) C(-6)	0
40	Lys8	anywhere	1164	Cx(6) Nx(2) C(-6) N(-2)	0
566	TMTpro16plex-Nter134N	anyNterm	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	16
567	TMTpro16plex-Lys126C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	1
568	TMTpro16plex-Lys127N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	2
569	TMTpro16plex-Lys127C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	3
570	TMTpro16plex-Lys128N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	4
571	TMTpro16plex-Lys128C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	5
572	TMTpro16plex-Lys129N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	6
573	TMTpro16plex-Lys129C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	7
574	TMTpro16plex-Lys130N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	8
575	TMTpro16plex-Lys130C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	9
576	TMTpro16plex-Lys131N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	10
577	TMTpro16plex-Lys131C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	11
578	TMTpro16plex-Lys132N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	12
579	TMTpro16plex-Lys132C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	13
580	TMTpro16plex-Lys133N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	14
581	TMTpro16plex-Lys133C	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	15
582	TMTpro16plex-Lys134N	anywhere	1509	H(25) C(8) Cx(7) N O(3) Nx(2)	16
583	N-Ethylmaleimide (C)	anywhere	1251	H(7) C(6) N O(2)	0
584	GlyGly (KST)	anywhere	1021	H(6) C(4) N(2) O(2)	0
585	2-monomethylsuccinyl (C)	anywhere	1542	H(6) C(5) O(4)	0
586	Dithiodipyridine (C)	anywhere	1543	H(3) C(5) S N	0
587	Arg10 (C-term)	anyCterm	1165	Cx(6) Nx(4) C(-6) N(-4)	0
588	Lys8 (C-term)	anyCterm	1164	Cx(6) Nx(2) C(-6) N(-2)	0
589	Phospho (R)	anywhere	1010	H O(3) P	0
\.


--
-- Name: t_maxquant_mods_mod_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_maxquant_mods_mod_id_seq', 589, true);


--
-- PostgreSQL database dump complete
--

