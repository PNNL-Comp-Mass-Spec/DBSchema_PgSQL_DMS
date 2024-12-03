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
-- Data for Name: t_default_psm_job_settings; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_default_psm_job_settings (entry_id, tool_name, job_type_name, stat_cys_alk, dyn_sty_phos, settings_file_name, enabled) FROM stdin;
122	MODa	High Res MS1	0	0	IonTrapDefSettings_DeconMSN.xml	1
123	MODa	High Res MS1	0	1	IonTrapDefSettings_DeconMSN.xml	1
124	MODa	High Res MS1	1	0	IonTrapDefSettings_DeconMSN.xml	1
125	MODa	High Res MS1	1	1	IonTrapDefSettings_DeconMSN.xml	1
134	MODa	Low Res MS1	0	0	IonTrapDefSettings.xml	1
135	MODa	Low Res MS1	0	1	IonTrapDefSettings.xml	1
136	MODa	Low Res MS1	1	0	IonTrapDefSettings.xml	1
137	MODa	Low Res MS1	1	1	IonTrapDefSettings.xml	1
126	MODa	iTRAQ 4-plex	0	0	IonTrapDefSettings_DeconMSN.xml	1
127	MODa	iTRAQ 4-plex	0	1	IonTrapDefSettings_DeconMSN.xml	1
128	MODa	iTRAQ 4-plex	1	0	IonTrapDefSettings_DeconMSN.xml	1
129	MODa	iTRAQ 4-plex	1	1	IonTrapDefSettings_DeconMSN.xml	1
130	MODa	iTRAQ 8-plex	0	0	IonTrapDefSettings_DeconMSN.xml	1
131	MODa	iTRAQ 8-plex	0	1	IonTrapDefSettings_DeconMSN.xml	1
132	MODa	iTRAQ 8-plex	1	0	IonTrapDefSettings_DeconMSN.xml	1
133	MODa	iTRAQ 8-plex	1	1	IonTrapDefSettings_DeconMSN.xml	1
23	MSGFPlus	High Res ms1	0	0	IonTrapDefSettings_DeconMSN.xml	0
29	MSGFPlus	High Res ms1	0	1	IonTrapDefSettings_DeconMSN.xml	0
26	MSGFPlus	High Res ms1	1	0	IonTrapDefSettings_DeconMSN.xml	0
32	MSGFPlus	High Res ms1	1	1	IonTrapDefSettings_DeconMSN.xml	0
22	MSGFPlus	Low Res ms1	0	0	IonTrapDefSettings.xml	0
28	MSGFPlus	Low Res ms1	0	1	IonTrapDefSettings.xml	0
25	MSGFPlus	Low Res ms1	1	0	IonTrapDefSettings.xml	0
31	MSGFPlus	Low Res ms1	1	1	IonTrapDefSettings.xml	0
207	MSGFPlus	TMT 16-plex	1	0	IonTrapDefSettings_MSConvert.xml	0
142	MSGFPlus	TMT 6-plex	0	0	IonTrapDefSettings_DeconMSN.xml	0
143	MSGFPlus	TMT 6-plex	0	1	IonTrapDefSettings_DeconMSN.xml	0
144	MSGFPlus	TMT 6-plex	1	0	IonTrapDefSettings_DeconMSN.xml	0
145	MSGFPlus	TMT 6-plex	1	1	IonTrapDefSettings_DeconMSN.xml	0
24	MSGFPlus	iTRAQ 4-plex	0	0	IonTrapDefSettings_DeconMSN.xml	0
30	MSGFPlus	iTRAQ 4-plex	0	1	IonTrapDefSettings_DeconMSN.xml	0
27	MSGFPlus	iTRAQ 4-plex	1	0	IonTrapDefSettings_DeconMSN.xml	0
33	MSGFPlus	iTRAQ 4-plex	1	1	IonTrapDefSettings_DeconMSN.xml	0
106	MSGFPlus	iTRAQ 8-plex	0	0	IonTrapDefSettings_DeconMSN.xml	0
107	MSGFPlus	iTRAQ 8-plex	0	1	IonTrapDefSettings_DeconMSN.xml	0
108	MSGFPlus	iTRAQ 8-plex	1	0	IonTrapDefSettings_DeconMSN.xml	0
109	MSGFPlus	iTRAQ 8-plex	1	1	IonTrapDefSettings_DeconMSN.xml	0
34	MSGFPlus_DTARefinery	High Res ms1	0	0	IonTrapDefSettings_DeconMSN_DTARef_NoMods.xml	0
38	MSGFPlus_DTARefinery	High Res ms1	0	1	IonTrapDefSettings_DeconMSN_DTARef_phospho.xml	0
36	MSGFPlus_DTARefinery	High Res ms1	1	0	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk.xml	0
40	MSGFPlus_DTARefinery	High Res ms1	1	1	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_phospho.xml	0
148	MSGFPlus_DTARefinery	TMT 6-plex	1	0	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_TMT6plex.xml	0
149	MSGFPlus_DTARefinery	TMT 6-plex	1	1	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_TMT6plex_phospho.xml	0
35	MSGFPlus_DTARefinery	iTRAQ 4-plex	0	0	IonTrapDefSettings_DeconMSN_DTARef_4plexITRAQ.xml	0
39	MSGFPlus_DTARefinery	iTRAQ 4-plex	0	1	IonTrapDefSettings_DeconMSN_DTARef_4plexITRAQ_phospho.xml	0
37	MSGFPlus_DTARefinery	iTRAQ 4-plex	1	0	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_4plexITRAQ.xml	0
41	MSGFPlus_DTARefinery	iTRAQ 4-plex	1	1	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_4plexITRAQ_phospho.xml	0
110	MSGFPlus_DTARefinery	iTRAQ 8-plex	0	0	IonTrapDefSettings_DeconMSN_DTARef_8plexITRAQ.xml	0
111	MSGFPlus_DTARefinery	iTRAQ 8-plex	0	1	IonTrapDefSettings_DeconMSN_DTARef_8plexITRAQ_phospho.xml	0
112	MSGFPlus_DTARefinery	iTRAQ 8-plex	1	0	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_8plexITRAQ.xml	0
113	MSGFPlus_DTARefinery	iTRAQ 8-plex	1	1	IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_8plexITRAQ_phospho.xml	0
186	MSGFPlus_MzML	High Res ms1	0	0	IonTrapDefSettings_MzML.xml	1
187	MSGFPlus_MzML	High Res ms1	0	1	IonTrapDefSettings_MzML_phospho.xml	1
188	MSGFPlus_MzML	High Res ms1	1	0	IonTrapDefSettings_MzML_StatCysAlk.xml	1
189	MSGFPlus_MzML	High Res ms1	1	1	IonTrapDefSettings_MzML_StatCysAlk_phospho.xml	1
205	MSGFPlus_MzML	TMT 16-plex	1	0	IonTrapDefSettings_MzML_StatCysAlk_16plexTMT.xml	1
206	MSGFPlus_MzML	TMT 16-plex	1	1	MzML_StatCysAlk_S_Phospho_Dyn_TY_Phospho_16plexTMT.xml	1
200	MSGFPlus_MzML	TMT 6-plex	0	0	IonTrapDefSettings_MzML_6plexTMT.xml	1
201	MSGFPlus_MzML	TMT 6-plex	0	1	IonTrapDefSettings_MzML_6plexTMT_phospho.xml	1
198	MSGFPlus_MzML	TMT 6-plex	1	0	IonTrapDefSettings_MzML_StatCysAlk_6plexTMT.xml	1
199	MSGFPlus_MzML	TMT 6-plex	1	1	IonTrapDefSettings_MzML_StatCysAlk_6plexTMT_phospho.xml	1
204	MSGFPlus_MzML	TMT Zero	1	0	IonTrapDefSettings_MzML_StatCysAlk_6plexTMT.xml	1
202	MSGFPlus_MzML	TMT Zero	1	1	IonTrapDefSettings_MzML_StatCysAlk_phospho.xml	1
190	MSGFPlus_MzML	iTRAQ 4-plex	0	0	IonTrapDefSettings_MzML_4plexITRAQ.xml	1
191	MSGFPlus_MzML	iTRAQ 4-plex	0	1	IonTrapDefSettings_MzML_4plexITRAQ_phospho.xml	1
192	MSGFPlus_MzML	iTRAQ 4-plex	1	0	IonTrapDefSettings_MzML_StatCysAlk_4plexITRAQ.xml	1
193	MSGFPlus_MzML	iTRAQ 4-plex	1	1	IonTrapDefSettings_MzML_StatCysAlk_4plexITRAQ_phospho.xml	1
194	MSGFPlus_MzML	iTRAQ 8-plex	0	0	IonTrapDefSettings_MzML_8plexITRAQ.xml	1
195	MSGFPlus_MzML	iTRAQ 8-plex	0	1	IonTrapDefSettings_MzML_8plexITRAQ_phospho.xml	1
196	MSGFPlus_MzML	iTRAQ 8-plex	1	0	IonTrapDefSettings_MzML_StatCysAlk_8plexITRAQ.xml	1
197	MSGFPlus_MzML	iTRAQ 8-plex	1	1	IonTrapDefSettings_MzML_StatCysAlk_8plexITRAQ_phospho.xml	1
3	Sequest	High Res ms1	0	0	FinniganDefSettings_DeconMSN.xml	0
9	Sequest	High Res ms1	0	1	FinniganDefSettings_DeconMSN.xml	0
6	Sequest	High Res ms1	1	0	FinniganDefSettings_DeconMSN.xml	0
12	Sequest	High Res ms1	1	1	FinniganDefSettings_DeconMSN.xml	0
1	Sequest	Low Res ms1	0	0	FinniganDefSettings.xml	0
8	Sequest	Low Res ms1	0	1	FinniganDefSettings.xml	0
5	Sequest	Low Res ms1	1	0	FinniganDefSettings.xml	0
11	Sequest	Low Res ms1	1	1	FinniganDefSettings.xml	0
4	Sequest	iTRAQ 4-plex	0	0	FinniganDefSettings_DeconMSN.xml	0
10	Sequest	iTRAQ 4-plex	0	1	FinniganDefSettings_DeconMSN.xml	0
7	Sequest	iTRAQ 4-plex	1	0	FinniganDefSettings_DeconMSN.xml	0
13	Sequest	iTRAQ 4-plex	1	1	FinniganDefSettings_DeconMSN.xml	0
114	Sequest	iTRAQ 8-plex	0	0	FinniganDefSettings_DeconMSN.xml	0
115	Sequest	iTRAQ 8-plex	0	1	FinniganDefSettings_DeconMSN.xml	0
116	Sequest	iTRAQ 8-plex	1	0	FinniganDefSettings_DeconMSN.xml	0
117	Sequest	iTRAQ 8-plex	1	1	FinniganDefSettings_DeconMSN.xml	0
14	Sequest_DTARefinery	High Res ms1	0	0	FinniganDefSettings_DeconMSN_DTARef_NoMods.xml	0
18	Sequest_DTARefinery	High Res ms1	0	1	FinniganDefSettings_DeconMSN_DTARef_phospho.xml	0
16	Sequest_DTARefinery	High Res ms1	1	0	FinniganDefSettings_DeconMSN_DTARef_StatCysAlk.xml	0
20	Sequest_DTARefinery	High Res ms1	1	1	FinniganDefSettings_DeconMSN_DTARef_StatCysAlk_phospho.xml	0
15	Sequest_DTARefinery	iTRAQ 4-plex	0	0	FinniganDefSettings_DeconMSN_DTARef_4plexITRAQ.xml	0
19	Sequest_DTARefinery	iTRAQ 4-plex	0	1	FinniganDefSettings_DeconMSN_DTARef_4plexITRAQ_phospho.xml	0
17	Sequest_DTARefinery	iTRAQ 4-plex	1	0	FinniganDefSettings_DeconMSN_DTARef_StatCysAlk_4plexITRAQ.xml	0
21	Sequest_DTARefinery	iTRAQ 4-plex	1	1	FinniganDefSettings_DeconMSN_DTARef_StatCysAlk_4plexITRAQ_phospho.xml	0
118	Sequest_DTARefinery	iTRAQ 8-plex	0	0	FinniganDefSettings_DeconMSN_DTARef_8plexITRAQ.xml	0
119	Sequest_DTARefinery	iTRAQ 8-plex	0	1	FinniganDefSettings_DeconMSN_DTARef_8plexITRAQ_phospho.xml	0
120	Sequest_DTARefinery	iTRAQ 8-plex	1	0	FinniganDefSettings_DeconMSN_DTARef_StatCysAlk_8plexITRAQ.xml	0
121	Sequest_DTARefinery	iTRAQ 8-plex	1	1	FinniganDefSettings_DeconMSN_DTARef_StatCysAlk_8plexITRAQ_phospho.xml	0
\.


--
-- Name: t_default_psm_job_settings_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_default_psm_job_settings_entry_id_seq', 207, true);


--
-- PostgreSQL database dump complete
--

