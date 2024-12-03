--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
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
-- Data for Name: t_aux_info_description; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_aux_info_description (aux_description_id, aux_description, aux_subcategory_id, sequence, data_size, helper_append, active) FROM stdin;
45	Genotype of Bacterium	244	1	64	N	Y
46	General Description of Experimental Test	244	2	64	N	Y
47	Date Started	245	1	64	N	Y
48	Date Completed	245	2	64	N	Y
49	Growth Media Recipe	245	3	64	N	Y
50	Source of Innoculum	245	4	64	N	Y
51	Volume of Culture	245	5	64	N	Y
52	Vessel used for Culture	245	6	64	N	Y
53	Growth Temperature	245	7	64	N	Y
54	Shaker Rate	245	8	64	N	Y
55	Duration of Incubation	245	9	64	N	Y
56	Comments	245	10	64	N	Y
57	Date Started	246	1	64	N	Y
58	Date Completed	246	2	64	N	Y
59	Growth Media Recipe	246	3	64	N	Y
60	Label (N14/N15)	246	4	64	N	Y
61	Volume of Culture	246	5	64	N	Y
62	Vessel used for Culture	246	6	64	N	Y
63	Growth Temperature	246	7	64	N	Y
64	Shaker Rate	246	8	64	N	Y
65	Duration of Incubation	246	9	64	N	Y
66	Harvest Time (after stress)	246	10	64	N	Y
67	Final OD at 600 (<1 for accuracy)	246	12	64	N	Y
68	Cell Count	246	13	64	N	Y
69	Harvest Growth Phase	246	14	64	N	Y
70	Harvest Conditions	246	15	64	N	Y
71	Stress Description	246	16	64	N	Y
72	Comments	246	17	64	N	Y
73	Centrifugation (G force, duration, temperature)	247	1	64	N	Y
74	Sample Wash	247	2	64	N	Y
75	Sample Fractionation	247	3	64	N	Y
76	Method	248	1	64	Y	Y
77	Ratio	248	2	64	N	Y
78	Note	248	3	256	N	Y
79	Beads	249	1	64	Y	Y
80	Centrifuge After	249	2	64	N	Y
81	Repetition	249	3	64	N	Y
82	Rpm	249	4	64	N	Y
83	Time	249	5	64	N	Y
84	Chemical	250	1	64	Y	Y
85	Time	250	2	64	N	Y
86	Temperature	251	1	64	N	Y
87	Time	251	2	64	N	Y
88	Temperature	252	1	64	N	Y
89	Time	252	2	64	N	Y
90	Setting	253	1	64	N	Y
91	Time	253	2	64	N	Y
92	Centrifuge Name	254	1	64	N	Y
93	Centrifuge Time	254	2	64	N	Y
94	Centrifuge Speed (RPM)	254	3	64	N	Y
96	Procedure Name	255	1	64	N	Y
97	Column Type	256	1	64	Y	Y
98	Buffer A	256	2	64	N	Y
99	Buffer B	256	3	64	N	Y
100	Gradient	256	4	64	N	Y
101	Time	256	5	64	N	Y
102	Reagent Type	257	1	64	A	Y
103	Concentration	257	2	64	N	Y
104	Time	257	3	64	N	Y
105	Reagent Type	258	1	64	Y	Y
106	Concentration	258	2	64	N	Y
107	Time	258	3	64	N	Y
108	Reagent Type	259	1	64	Y	Y
109	Concentration	259	2	64	N	Y
110	Time	259	3	64	N	Y
111	Type	260	1	64	Y	Y
112	Concentration	260	2	64	N	Y
113	Alkylation Agent	261	1	64	N	Y
114	Temperature	261	2	64	N	Y
115	Time	261	3	64	N	Y
116	Labeling Procedure	262	1	64	Y	Y
117	Buffer Type	263	1	64	Y	Y
118	Concentration (mM)	263	2	64	N	Y
119	PH	263	3	64	N	Y
120	Column or Method	264	1	64	Y	Y
121	Enzyme Type	265	1	64	Y	Y
122	Enzyme to Protein ratio	265	2	64	N	Y
123	Time	265	3	64	N	Y
124	Antibody Affinity	266	4	64	Y	Y
125	Column Type	267	1	64	Y	Y
126	MWCO	268	1	64	N	Y
127	Buffer	268	2	64	N	Y
128	Membrane	268	4	120	Y	Y
129	Concentration	269	1	64	N	Y
130	Lyophilization	269	2	64	Y	Y
131	Volume	269	3	64	N	Y
132	Room	270	1	64	N	N
133	Freezer	270	2	64	N	N
134	Shelf	270	3	64	N	N
135	Drawer	270	4	64	N	N
136	Row	270	5	64	N	N
137	Box	270	6	64	N	N
138	Volume of buffer used	268	3	64	N	Y
139	Solvent System	271	1	32	N	N
140	Packing Material	271	2	32	N	N
141	Column Length	271	3	32	N	N
142	Pump System	271	4	32	N	N
143	Column In-service Date	271	5	32	N	N
144	Column Inner Dia.	271	6	32	N	N
149	Oxidizing Agent	262	3	64	Y	Y
150	Oxidation Incubation Time	262	4	64	N	Y
151	Molar Excess of Label Over Cys Residues	262	5	64	N	Y
152	Labelling Incubation Time	262	6	64	N	Y
153	Type of Column	275	1	64	N	Y
154	Bed Volume / Size of Column	275	2	64	N	Y
155	Size of Fractions Collected	275	3	64	N	Y
157	Bed Volume	276	1	64	N	Y
158	Elution Buffer Used	276	2	64	N	Y
159	Size of Fractions Collected	276	3	64	N	Y
160	Time	277	1	64	N	Y
161	Temperature	277	2	64	N	Y
162	Incubation Time	260	3	64	N	Y
163	Incubation Conditions	260	4	256	N	Y
164	Column Outer Dia.	271	7	64	N	N
165	Gradient Program	271	8	64	N	N
166	Comment	271	9	256	N	N
167	Source	278	1	64	Y	Y
168	Proposal Number	278	2	64	N	Y
169	Comment	249	6	256	N	Y
170	Amount of Cells	249	7	64	Y	Y
171	Incubation Temperature	265	1	64	N	Y
172	RPM	279	1	64	N	Y
173	Time	279	2	64	N	Y
174	Temperature	279	3	64	N	Y
175	Volume of Labeling Agent	262	7	32	N	Y
176	Room	280	1	64	N	N
177	Freezer	280	2	64	N	N
178	Shelf	280	3	64	N	N
179	Drawer	280	4	64	N	N
180	Row	280	5	64	N	N
181	Box	280	6	64	N	N
182	Replicate of (sample name)	281	1	64	N	Y
183	Cultivation Method	281	2	64	N	Y
184	Medium Name	281	3	64	N	Y
185	Medium Component Varion(s) (name, conc)	281	4	256	N	Y
186	Aerobicity	281	5	64	N	Y
187	Dissolved Oxygen (% air sat.)	281	6	64	N	Y
188	Electro Donor(s) (name, conc)	281	7	64	N	Y
189	Electron Acceptor(s) (name, conc)	281	8	64	N	Y
190	Dilution Rate (h -1)	281	9	64	N	Y
191	Growth Rate (h -1)	281	10	64	N	Y
192	Carbon Source (name, conc)	281	11	64	N	Y
193	Growth Limiting Nutrient (name, conc)	281	12	64	N	Y
194	Liquid Volume of Culture (L)	281	13	64	N	Y
195	Gas Composition	281	14	64	N	Y
196	Gas Flow Rate (L/min)	281	15	64	N	Y
197	Temperature (C)	281	16	64	N	Y
198	pH	281	17	64	N	Y
199	Agitation (RPM)	281	18	64	N	Y
200	Column type	282	1	64	Y	Y
201	Buffer A	282	2	64	N	Y
202	Buffer B	282	3	64	N	Y
203	Gradient	282	4	64	N	Y
204	Time	282	5	64	N	Y
205	Num. Fractions	282	6	64	N	Y
206	Fraction Size	282	7	64	N	Y
207	Room	283	1	64	N	N
208	Freezer	283	2	64	N	N
209	Shelf	283	3	64	N	N
210	Drawer	283	4	64	N	N
211	Row	283	5	64	N	N
212	Box	283	6	64	N	N
213	Mandated by	284	1	64	N	Y
214	Specific Hazards	284	2	256	N	Y
215	Protective Equipment Required	284	3	128	Y	Y
216	Other Comments	284	4	256	N	Y
217	Type	285	1	64	N	Y
218	Buffer used	285	2	64	N	Y
219	Plate	286	1	64	N	N
220	Well	286	2	64	N	N
221	Number of Cycles	287	1	64	N	Y
222	Pressure	287	2	64	N	Y
224	Time	287	4	64	N	Y
225	Time at Ambient Pressure	287	5	64	N	Y
226	Column Type	288	1	64	Y	Y
227	Buffer A	288	2	64	N	N
228	Buffer B	288	3	64	N	N
229	Gradient	288	5	64	N	N
230	Time	288	6	64	N	Y
231	Fraction Collection	288	7	64	N	Y
262	Lysis Disk	287	6	64	Y	Y
263	Prep by Robot	267	2	5	Y	Y
264	Buffer C	288	4	64	N	N
265	Time Series	293	1	64	N	Y
266	Replicates	293	2	64	N	Y
\.


--
-- Name: t_aux_info_description_aux_description_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_aux_info_description_aux_description_id_seq', 266, true);


--
-- PostgreSQL database dump complete
--

