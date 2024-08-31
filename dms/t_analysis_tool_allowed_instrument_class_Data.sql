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
-- Data for Name: t_analysis_tool_allowed_instrument_class; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_analysis_tool_allowed_instrument_class (analysis_tool_id, instrument_class, comment) FROM stdin;
1	Finnigan_Ion_Trap	
1	LTQ_FT	
1	Sciex_TripleTOF	
2	BRUKERFTMS	
2	BrukerFT_BAF	
2	Finnigan_FTICR	
3	Finnigan_Ion_Trap	
4	BRUKERFTMS	
4	Finnigan_FTICR	
5	Finnigan_Ion_Trap	
6	QStar_QTOF	
7	QStar_QTOF	
8	Finnigan_Ion_Trap	
9	Agilent_Ion_Trap	
10	Waters_TOF	
11	Agilent_TOF	
12	LTQ_FT	
12	Thermo_Exactive	
13	Finnigan_Ion_Trap	
13	LTQ_FT	
13	Thermo_Exactive	
13	Triple_Quad	
14	Agilent_Ion_Trap	
15	Finnigan_Ion_Trap	
15	LTQ_FT	
15	Sciex_TripleTOF	
16	BRUKERFTMS	
16	Finnigan_FTICR	
16	Finnigan_Ion_Trap	
16	IMS_Agilent_TOF_DotD	
16	IMS_Agilent_TOF_UIMF	
16	LTQ_FT	
16	Thermo_Exactive	
16	Waters_TOF	
17	BRUKERFTMS	
17	Finnigan_FTICR	
17	Finnigan_Ion_Trap	
17	IMS_Agilent_TOF_DotD	
17	IMS_Agilent_TOF_UIMF	
17	LTQ_FT	
17	Thermo_Exactive	
17	Waters_TOF	
18	Agilent_TOF	
19	Agilent_TOF	
20	Finnigan_Ion_Trap	
20	LTQ_FT	
21	Finnigan_Ion_Trap	
21	IMS_Agilent_TOF_DotD	
21	IMS_Agilent_TOF_UIMF	
21	LTQ_FT	
21	Thermo_Exactive	
21	Triple_Quad	
22	Finnigan_Ion_Trap	
22	LTQ_FT	
23	Finnigan_Ion_Trap	
23	LTQ_FT	
24	Finnigan_Ion_Trap	
24	LTQ_FT	
25	Finnigan_Ion_Trap	
25	LTQ_FT	
26	Finnigan_Ion_Trap	
26	LTQ_FT	
27	Agilent_Ion_Trap	
27	Agilent_TOF	
27	Agilent_TOF_V2	
27	BRUKERFTMS	
27	BrukerFT_BAF	
27	BrukerMALDI_Imaging	
27	BrukerMALDI_Spot	
27	BrukerTOF_BAF	
27	Finnigan_FTICR	
27	Finnigan_Ion_Trap	
27	IMS_Agilent_TOF_DotD	
27	IMS_Agilent_TOF_UIMF	
27	LTQ_FT	
27	Thermo_Exactive	
27	Waters_TOF	
28	Finnigan_Ion_Trap	
28	LTQ_FT	
29	Finnigan_Ion_Trap	
29	LTQ_FT	
29	Sciex_TripleTOF	
30	Finnigan_Ion_Trap	
30	LTQ_FT	
31	Finnigan_Ion_Trap	
31	LTQ_FT	
32	Finnigan_Ion_Trap	
32	LTQ_FT	
33	Agilent_Ion_Trap	
33	Agilent_TOF_V2	
33	BRUKERFTMS	
33	BrukerFT_BAF	
33	BrukerMALDI_Imaging	
33	BrukerMALDI_Spot	
33	Finnigan_FTICR	
33	Finnigan_Ion_Trap	
33	IMS_Agilent_TOF_DotD	
33	IMS_Agilent_TOF_UIMF	
33	LTQ_FT	
33	Thermo_Exactive	
33	Waters_TOF	
34	BrukerFT_BAF	
34	BrukerTOF_BAF	
34	Bruker_Amazon_Ion_Trap	
35	Agilent_Ion_Trap	
35	Agilent_TOF_V2	
35	BRUKERFTMS	
35	BrukerFT_BAF	
35	BrukerMALDI_Imaging	
35	BrukerMALDI_Spot	
35	Finnigan_FTICR	
35	Finnigan_Ion_Trap	
35	IMS_Agilent_TOF_DotD	
35	IMS_Agilent_TOF_UIMF	
35	LTQ_FT	
35	Thermo_Exactive	
35	Waters_TOF	
36	BrukerTOF_TDF	
36	Finnigan_Ion_Trap	
36	LTQ_FT	
36	Sciex_TripleTOF	
37	Finnigan_Ion_Trap	
37	LTQ_FT	
37	Sciex_TripleTOF	
38	Agilent_TOF_V2	
38	Finnigan_Ion_Trap	
38	LTQ_FT	
38	Thermo_Exactive	
39	Finnigan_Ion_Trap	
39	LTQ_FT	
39	Sciex_TripleTOF	
40	BrukerFT_BAF	
41	Finnigan_Ion_Trap	
41	LTQ_FT	
41	Thermo_Exactive	
41	Triple_Quad	
47	BrukerFT_BAF	
48	BrukerTOF_BAF	
48	Bruker_Amazon_Ion_Trap	
51	LTQ_FT	
52	IMS_Agilent_TOF_DotD	
52	IMS_Agilent_TOF_UIMF	
53	Finnigan_Ion_Trap	
53	LTQ_FT	
53	Thermo_Exactive	
53	Triple_Quad	
59	Finnigan_Ion_Trap	
59	LTQ_FT	
60	Finnigan_Ion_Trap	
60	LTQ_FT	
60	Sciex_TripleTOF	
61	BrukerTOF_BAF	
61	Waters_TOF	
63	Finnigan_Ion_Trap	
63	LTQ_FT	
63	Sciex_TripleTOF	
64	Finnigan_Ion_Trap	
64	LTQ_FT	
65	Finnigan_Ion_Trap	
65	LTQ_FT	
66	Finnigan_Ion_Trap	
66	LTQ_FT	
66	Thermo_Exactive	
67	Finnigan_Ion_Trap	
67	LTQ_FT	
67	Thermo_Exactive	
68	Agilent_TOF_V2	
68	Finnigan_Ion_Trap	
68	LTQ_FT	
68	Sciex_TripleTOF	
69	Agilent_TOF_V2	
69	Finnigan_Ion_Trap	
69	LTQ_FT	
69	Sciex_TripleTOF	
70	Finnigan_Ion_Trap	
70	LTQ_FT	
70	Thermo_Exactive	
71	BrukerFT_BAF	
71	BrukerTOF_BAF	
71	Bruker_Amazon_Ion_Trap	
72	BrukerFT_BAF	
72	BrukerTOF_BAF	
73	Finnigan_Ion_Trap	
73	LTQ_FT	
74	Finnigan_Ion_Trap	
74	LTQ_FT	
75	Finnigan_Ion_Trap	
75	LTQ_FT	
75	Thermo_Exactive	
75	Triple_Quad	
76	Finnigan_Ion_Trap	
76	LTQ_FT	
76	Thermo_Exactive	
77	BrukerFT_BAF	
77	BrukerTOF_BAF	
78	Finnigan_Ion_Trap	
78	LTQ_FT	
78	Sciex_TripleTOF	
79	Agilent_TOF_V2	
79	Finnigan_Ion_Trap	
79	LTQ_FT	
79	Sciex_TripleTOF	
81	BrukerFT_BAF	
83	Agilent_TOF_V2	
83	Finnigan_Ion_Trap	
83	LTQ_FT	
83	Thermo_Exactive	
85	LTQ_FT	
86	Finnigan_Ion_Trap	
86	LTQ_FT	
87	BrukerFT_BAF	
88	Agilent_TOF_V2	
88	Finnigan_Ion_Trap	
88	LTQ_FT	
90	Agilent_TOF_V2	
90	Finnigan_Ion_Trap	
90	LTQ_FT	
90	Sciex_TripleTOF	
91	Agilent_TOF_V2	
91	Finnigan_Ion_Trap	
91	LTQ_FT	
92	Agilent_TOF_V2	
92	Finnigan_Ion_Trap	
92	LTQ_FT	
\.


--
-- PostgreSQL database dump complete
--

