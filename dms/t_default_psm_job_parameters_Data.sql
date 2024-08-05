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
-- Data for Name: t_default_psm_job_parameters; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_default_psm_job_parameters (entry_id, job_type_name, tool_name, dyn_met_ox, stat_cys_alk, dyn_sty_phos, parameter_file_name, enabled) FROM stdin;
1	Low Res MS1	Sequest	0	0	0	sequest_N14_PartTryp.params	0
13	High Res MS1	Sequest	1	1	0	sequest_N14_PartTryp_Dyn_M_Ox_Stat_Cys_Alk.params	0
14	iTRAQ 4-plex	Sequest	1	1	0	sequest_HCD_N14_PartTryp_DynMetOx_StatIodo_ITRAQ_4PLEX_Par50ppmFrag0pt05Da.params	0
15	Low Res MS1	MSGFPlus_MzML	0	0	0	MSGFPlus_PartTryp_NoMods.txt	1
16	High Res MS1	MSGFPlus_MzML	0	0	0	MSGFPlus_PartTryp_NoMods_20ppmParTol.txt	1
17	iTRAQ 4-plex	MSGFPlus_MzML	0	0	0	MSGFPlus_PartTryp_iTRAQ_4Plex_20ppmParTol.txt	1
18	iTRAQ 4-plex	MSGFPlus_MzML	0	0	1	MSGFPlus_PartTryp_DynSTYPhos_iTRAQ_4Plex_20ppmParTol.txt	1
19	Low Res MS1	MSGFPlus_MzML	0	1	0	MSGFPlus_PartTryp_StatCysAlk.txt	1
20	High Res MS1	MSGFPlus_MzML	0	1	0	MSGFPlus_PartTryp_StatCysAlk_20ppmParTol.txt	1
21	iTRAQ 4-plex	MSGFPlus_MzML	0	1	0	MSGFPlus_PartTryp_Stat_CysAlk_iTRAQ_4Plex_20ppmParTol.txt	1
22	iTRAQ 4-plex	MSGFPlus_MzML	0	1	1	MSGFPlus_PartTryp_DynSTYPhos_Stat_CysAlk_iTRAQ_4Plex_20ppmParTol.txt	1
23	Low Res MS1	MSGFPlus_MzML	1	0	0	MSGFPlus_PartTryp_MetOx.txt	1
24	High Res MS1	MSGFPlus_MzML	1	0	0	MSGFPlus_PartTryp_MetOx_20ppmParTol.txt	1
25	iTRAQ 4-plex	MSGFPlus_MzML	1	0	0	MSGFPlus_PartTryp_DynMetOx_iTRAQ_4Plex_20ppmParTol.txt	1
26	Low Res MS1	MSGFPlus_MzML	1	1	0	MSGFPlus_PartTryp_MetOx_StatCysAlk.txt	1
27	High Res MS1	MSGFPlus_MzML	1	1	0	MSGFPlus_PartTryp_MetOx_StatCysAlk_20ppmParTol.txt	1
28	iTRAQ 4-plex	MSGFPlus_MzML	1	1	0	MSGFPlus_PartTryp_DynMetOx_Stat_CysAlk_iTRAQ_4Plex_20ppmParTol.txt	1
29	iTRAQ 8-plex	MSGFPlus_MzML	0	0	0	MSGFPlus_PartTryp_iTRAQ_8Plex_20ppmParTol.txt	1
30	iTRAQ 8-plex	MSGFPlus_MzML	0	0	1	MSGFPlus_PartTryp_DynSTYPhos_iTRAQ_8Plex_20ppmParTol.txt	1
31	iTRAQ 8-plex	MSGFPlus_MzML	0	1	0	MSGFPlus_PartTryp_Stat_CysAlk_iTRAQ_8Plex_20ppmParTol.txt	1
32	iTRAQ 8-plex	MSGFPlus_MzML	0	1	1	MSGFPlus_PartTryp_DynSTYPhos_Stat_CysAlk_iTRAQ_8Plex_20ppmParTol.txt	1
2	High Res MS1	Sequest	0	0	0	sequest_N14_PartTryp.params	0
3	iTRAQ 4-plex	Sequest	0	0	0	sequest_HCD_N14_PartTryp_ITRAQ_4PLEX_Par50ppmFrag0pt05Da.params	0
4	iTRAQ 4-plex	Sequest	0	0	1	sequest_HCD_N14_PartTryp_DynSTYPhos_ITRAQ_4PLEX_Par50ppmFrag0pt05Da.params	0
5	Low Res MS1	Sequest	0	1	0	sequest_N14_PartTryp_Stat_C_Iodo.params	0
6	High Res MS1	Sequest	0	1	0	sequest_N14_PartTryp_Stat_C_Iodo.params	0
7	iTRAQ 4-plex	Sequest	0	1	0	sequest_HCD_N14_PartTryp_Stat_C_Iodo_ITRAQ_4PLEX_Par50ppmFrag0pt05Da.params	0
8	iTRAQ 4-plex	Sequest	0	1	1	sequest_HCD_N14_PartTryp_DynSTYPhos_Stat_C_Iodo_ITRAQ_4PLEX_Par50ppmFrag0pt05Da.params	0
9	Low Res MS1	Sequest	1	0	0	sequest_N14_PartTryp_Dyn_M_Ox.params	0
10	High Res MS1	Sequest	1	0	0	sequest_N14_PartTryp_Dyn_M_Ox.params	0
11	iTRAQ 4-plex	Sequest	1	0	0	sequest_HCD_N14_PartTryp_DynMetOx_ITRAQ_4PLEX_Par50ppmFrag0pt05Da.params	0
12	Low Res MS1	Sequest	1	1	0	sequest_N14_PartTryp_Dyn_M_Ox_Stat_Cys_Alk.params	0
33	iTRAQ 8-plex	MSGFPlus_MzML	1	0	0	MSGFPlus_PartTryp_DynMetOx_iTRAQ_8Plex_20ppmParTol.txt	1
34	iTRAQ 8-plex	MSGFPlus_MzML	1	1	0	MSGFPlus_PartTryp_DynMetOx_Stat_CysAlk_iTRAQ_8Plex_20ppmParTol.txt	1
35	iTRAQ 8-plex	Sequest	1	1	0	sequest_HCD_N14_PartTryp_DynMetOx_Stat_Cys_Iodo_ITRAQ_8PLEX_Par50ppmFrag0pt05Da.params	0
60	High Res MS1	MODa	0	0	0	MODa_PartTryp_Par20ppm_Frag0pt6Da.txt	1
61	High Res MS1	MODa	0	1	0	MODa_PartTryp_CysAlk_Par20ppm_Frag0pt6Da.txt	1
62	iTRAQ 4-plex	MODa	0	0	0	MODa_PartTryp_iTRAQ_4Plex_Par20ppm_Frag0pt6Da.txt	1
63	iTRAQ 4-plex	MODa	0	1	0	MODa_PartTryp_CysAlk_iTRAQ_4Plex_Par20ppm_Frag0pt6Da.txt	1
64	iTRAQ 8-plex	MODa	0	0	0	MODa_PartTryp_iTRAQ_8Plex_Par20ppm_Frag0pt6Da.txt	1
65	iTRAQ 8-plex	MODa	0	1	0	MODa_PartTryp_CysAlk_iTRAQ_8Plex_Par20ppm_Frag0pt6Da.txt	1
66	Low Res MS1	MODa	0	0	0	MODa_PartTryp_Par3Da_Frag0pt6Da.txt	1
67	Low Res MS1	MODa	0	1	0	MODa_PartTryp_CysAlk_Par3Da_Frag0pt6Da.txt	1
68	High Res MS1	MODa	1	0	0	MODa_PartTryp_Par20ppm_Frag0pt6Da.txt	1
69	High Res MS1	MODa	1	1	0	MODa_PartTryp_CysAlk_Par20ppm_Frag0pt6Da.txt	1
70	iTRAQ 4-plex	MODa	1	0	0	MODa_PartTryp_iTRAQ_4Plex_Par20ppm_Frag0pt6Da.txt	1
71	iTRAQ 4-plex	MODa	1	1	0	MODa_PartTryp_CysAlk_iTRAQ_4Plex_Par20ppm_Frag0pt6Da.txt	1
72	iTRAQ 8-plex	MODa	1	0	0	MODa_PartTryp_iTRAQ_8Plex_Par20ppm_Frag0pt6Da.txt	1
73	iTRAQ 8-plex	MODa	1	1	0	MODa_PartTryp_CysAlk_iTRAQ_8Plex_Par20ppm_Frag0pt6Da.txt	1
74	Low Res MS1	MODa	1	0	0	MODa_PartTryp_Par3Da_Frag0pt6Da.txt	1
75	Low Res MS1	MODa	1	1	0	MODa_PartTryp_CysAlk_Par3Da_Frag0pt6Da.txt	1
76	High Res MS1	MODa	0	0	1	MODa_PartTryp_Par20ppm_Frag0pt6Da.txt	1
77	High Res MS1	MODa	0	1	1	MODa_PartTryp_CysAlk_Par20ppm_Frag0pt6Da.txt	1
78	iTRAQ 4-plex	MODa	0	0	1	MODa_PartTryp_iTRAQ_4Plex_Par20ppm_Frag0pt6Da.txt	1
79	iTRAQ 4-plex	MODa	0	1	1	MODa_PartTryp_CysAlk_iTRAQ_4Plex_Par20ppm_Frag0pt6Da.txt	1
80	iTRAQ 8-plex	MODa	0	0	1	MODa_PartTryp_iTRAQ_8Plex_Par20ppm_Frag0pt6Da.txt	1
81	iTRAQ 8-plex	MODa	0	1	1	MODa_PartTryp_CysAlk_iTRAQ_8Plex_Par20ppm_Frag0pt6Da.txt	1
82	Low Res MS1	MODa	0	0	1	MODa_PartTryp_Par3Da_Frag0pt6Da.txt	1
83	Low Res MS1	MODa	0	1	1	MODa_PartTryp_CysAlk_Par3Da_Frag0pt6Da.txt	1
84	High Res MS1	MSGFPlus_MzML	0	0	1	MSGFPlus_PartTryp_DynSTYPhos_20ppmParTol.txt	1
85	High Res MS1	MSGFPlus_MzML	0	1	1	MSGFPlus_Tryp_DynSTYPhos_Stat_CysAlk_20ppmParTol.txt	1
92	TMT 6-plex	MSGFPlus_MzML	0	0	0	MSGFPlus_PartTryp_TMT_6Plex_20ppmParTol.txt	1
95	TMT 6-plex	MSGFPlus_MzML	0	1	1	MSGFPlus_PartTryp_DynSTYPhos_Stat_CysAlk_TMT_6Plex_Protocol1_20ppmParTol.txt	1
96	TMT 6-plex	MSGFPlus_MzML	1	0	0	MSGFPlus_PartTryp_DynMetOx_Stat_TMT_6Plex_20ppmParTol.txt	1
97	TMT 6-plex	MSGFPlus_MzML	1	1	0	MSGFPlus_PartTryp_DynMetOx_Stat_CysAlk_TMT_6Plex_20ppmParTol.txt	1
104	TMT 6-plex	MSGFPlus_MzML	1	1	1	MSGFPlus_PartTryp_Dyn_MetOx_STYPhos_Stat_CysAlk_TMT_6Plex_Protocol1_20ppmParTol.txt	1
105	TMT 6-plex	MSGFPlus_MzML	0	1	0	MSGFPlus_PartTryp_Stat_CysAlk_TMT_6Plex_20ppmParTol.txt	1
107	TMT 6-plex	MSGFPlus_MzML	0	0	1	MSGFPlus_PartTryp_DynSTYPhos_Stat_TMT_6Plex_Protocol1_20ppmParTol.txt	1
109	High Res MS1	MSGFPlus_MzML	1	1	1	MSGFPlus_Tryp_Dyn_MetOx_STYPhos_Stat_CysAlk_20ppmParTol.txt	1
110	TMT Zero	MSGFPlus_MzML	1	1	0	MSGFPlus_PartTryp_DynMetOx_Stat_CysAlk_TMT_Zero_10ppmParTol.txt	1
111	TMT Zero	MSGFPlus_MzML	0	1	1	MSGFPlus_PartTryp_DynSTYPhos_Stat_CysAlk_TMT_Zero_Protocol1_20ppmParTol.txt	1
112	TMT 16-plex	MSGFPlus_MzML	1	1	0	MSGFPlus_PartTryp_DynMetOx_Stat_CysAlk_TMT_16Plex_20ppmParTol.txt	1
113	TMT 16-plex	MSGFPlus_MzML	1	1	1	MSGFPlus_PartTryp_Dyn_MetOx_STYPhos_Stat_CysAlk_TMT_16Plex_Protocol1_20ppmParTol.txt	1
114	TMT 16-plex	MSGFPlus_MzML	0	1	1	MSGFPlus_PartTryp_DynSTYPhos_Stat_CysAlk_TMT_16Plex_Protocol1_20ppmParTol.txt	1
115	TMT 16-plex	MSGFPlus_MzML	0	0	0	MSGFPlus_PartTryp_TMT_16Plex_20ppmParTol.txt	1
116	TMT 16-plex	MSGFPlus_MzML	0	0	1	MSGFPlus_PartTryp_DynSTYPhos_Stat_TMT_16Plex_Protocol1_20ppmParTol.txt	1
117	TMT 16-plex	MSGFPlus_MzML	1	0	0	MSGFPlus_PartTryp_DynMetOx_Stat_TMT_16Plex_20ppmParTol.txt	1
118	TMT 16-plex	MSGFPlus_MzML	0	1	0	MSGFPlus_PartTryp_Stat_CysAlk_TMT_16Plex_20ppmParTol.txt	1
\.


--
-- Name: t_default_psm_job_parameters_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_default_psm_job_parameters_entry_id_seq', 118, true);


--
-- PostgreSQL database dump complete
--

