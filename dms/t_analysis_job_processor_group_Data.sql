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
-- Data for Name: t_analysis_job_processor_group; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_analysis_job_processor_group (group_id, group_name, group_description, group_enabled, group_created, last_affected, entered_by) FROM stdin;
100	General Processors	 (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2007-02-23 19:07:08	2023-07-31 14:41:18	PNL\\D3L243
102	Tom Metz Pubs	All four Decon2LS PCs purchased by Tom Metz	N	2007-02-23 19:16:22	2011-03-18 16:42:00	pnl\\D3L243
103	Sequest Cluster 3	\N	N	2007-02-23 19:20:29	2016-02-15 17:47:21	PNL\\D3L243
105	DAC_Desktop	DAC development machine	N	2007-03-01 14:00:45	2011-03-18 16:36:31	D3L243 (via DMSWebUser)
106	Sequest Clusters 1, 3, and 4	All full-sized clusters	N	2007-03-05 13:05:42	2016-02-15 17:47:24	PNL\\D3L243
107	Sequest Cluster 2	 (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2007-03-05 13:21:25	2023-07-31 14:41:18	PNL\\D3L243
108	Sequest Cluster 1	\N	N	2007-03-06 09:45:56	2023-07-31 14:41:18	PNL\\D3L243
109	Sequest Cluster 4		N	2007-03-06 09:46:16	2016-02-15 17:47:34	PNL\\D3L243
110	ICR2LS Processors		N	2007-03-15 18:32:39	2011-03-18 16:42:00	pnl\\D3L243
111	Pub-43	Pub-43 test group using all four processors	N	2007-03-16 14:33:33	2011-03-18 16:40:35	pnl\\D3L243
112	Sequest Clusters 1, 2, and 3	All clusters except 4	N	2007-04-04 10:56:37	2016-02-15 17:47:44	PNL\\D3L243
113	Pub-01	Group for testing Pub-01	N	2007-04-05 16:44:18	2011-03-18 16:39:13	D3L243 (via DMSWebUser)
114	Xeon Woodcrest Pubs	The 3 fastest Decon2LS PCs	N	2007-04-18 15:07:56	2009-10-13 16:05:27	pnl\\D3L243
115	MASIC High Performance	MASIC PCs with fast CPUs and >1 GB Ram	N	2007-04-24 07:46:42	2016-02-15 17:47:49	PNL\\D3L243
116	Sequest Clusters 1 and 2	First 2 clusters (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2007-04-24 09:53:31	2023-07-31 14:41:18	PNL\\D3L243
117	Sequest Clusters 2 and 3	Clusters 2 and 3	N	2007-05-14 10:50:15	2016-02-15 17:47:51	PNL\\D3L243
119	Sequest Clusters 1 and 4	Clusters 1 and 4	N	2007-07-02 10:53:05	2016-02-15 17:47:52	PNL\\D3L243
120	Pub-12	Pub-12	N	2007-07-06 17:06:50	2009-01-25 16:49:21	PNL\\D3L243
123	Pub-40	Pub-40	N	2007-07-06 17:51:39	2011-03-18 16:39:44	D3L243 (via DMSWebUser)
125	Sequest Clusters 2 and 4	Clusters 2 and 4	N	2007-07-26 11:40:33	2016-02-15 17:47:52	PNL\\D3L243
128	Pub-21	Pub-21 XTandem	N	2007-09-28 13:21:49	2011-03-18 16:39:36	D3L243 (via DMSWebUser)
129	XTandem on Pub-4x PCs	XTandem on quad-processor PCs	N	2007-10-10 16:30:15	2009-01-24 15:49:05	PNL\\D3L243
130	Sequest Clusters 1 and 3	P0 and Chameleon	N	2007-10-26 09:45:57	2016-02-15 17:47:54	PNL\\D3L243
132	Monroe	MEM development machine (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2008-02-22 12:32:56	2023-07-31 14:41:18	PNL\\D3L243
133	Inspect Processors		N	2008-10-08 17:04:09	2009-01-24 15:49:27	PNL\\D3L243
134	Sequest Clusters 3 and 4	Clusters 3 and 4	N	2008-11-10 09:57:53	2016-02-15 17:48:00	PNL\\D3L243
135	Sequest Cluster 5	Sequest cluster 5 only (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2008-11-17 10:00:41	2023-07-31 14:41:18	PNL\\D3L243
136	Sequest Clusters 4 and 5	Clusters 4 and 5	N	2008-12-08 11:25:04	2016-02-15 17:48:02	PNL\\D3L243
137	Sequest Clusters 1 and 5	Clusters 1 and 5 (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2009-01-23 17:54:22	2023-07-31 14:41:18	PNL\\D3L243
138	Pub-17	Pub-17	N	2009-01-25 21:49:41	2011-03-18 16:39:27	D3L243 (via DMSWebUser)
139	Sequest Clusters 1, 2, and 5	Clusters 1, 2, and 5	N	2009-02-07 23:06:48	2016-02-15 17:48:04	PNL\\D3L243
140	Sequest Clusters 1, 3, 4, and 5	All except SeqCluster2	N	2009-06-04 15:20:55	2016-02-15 17:48:05	PNL\\D3L243
141	Sequest Clusters 1, 2, 3, and 4	All except SeqCluster5	N	2009-06-04 15:59:58	2016-02-15 17:48:05	PNL\\D3L243
142	Decon2LS_V2	Group for Pub boxes running Decon2LS_V2 (supports UIMF files and RAPID processing)	N	2009-06-23 19:56:36	2011-03-18 16:42:00	pnl\\D3L243
143	Sequest Cluster 1 DTA Testing	\N	N	2009-07-08 11:17:26	2011-03-18 16:42:01	pnl\\D3L243
144	R610 Pubs 50-59	Dell R610 Pubs 50 through 59	N	2009-11-17 13:44:33	2011-03-18 16:42:01	pnl\\D3L243
145	Sequest Clusters 3 and 5	Clusters 3 and 5	N	2010-04-05 11:13:48	2016-02-15 17:48:07	PNL\\D3L243
146	Sequest Clusters 2 and 5	Clusters 2 and 5 (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2010-04-20 10:03:45	2023-07-31 14:41:18	PNL\\D3L243
147	Sequest Clusters 2, 3, and 5	Clusters 2, 3, and 5	N	2010-04-27 09:21:03	2016-02-15 17:48:09	PNL\\D3L243
148	R610 Pubs, Group 1, Mgrs 2 and 4	Pubs 36-39, 44-69, 80-89; Mgrs 2 and 4 only	N	2010-09-27 20:27:01	2016-02-15 17:46:55	PNL\\D3L243
149	Sequest Clusters 2, 3, and 4	Clusters 2, 3, and 4	N	2011-03-18 16:34:01	2016-02-15 17:48:10	PNL\\D3L243
150	Sequest Clusters 1, 3, and 5	Clusters 1, 3, and 5	N	2012-04-18 15:31:28	2016-02-15 17:48:23	PNL\\D3L243
151	R610 Pubs, Group 2, Mgrs 3 and 5	Pubs 70-89; Mgrs 3 and 5 only	N	2013-01-29 17:39:17	2016-02-15 17:46:52	PNL\\D3L243
152	R610 Pubs, Group A, Mgrs 3 and 5	Pubs 36-39, 44-49; Mgrs 3 and 5 (MSGF+ managers) (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2016-02-15 17:44:11	2023-07-31 14:41:18	PNL\\D3L243
153	R610 Pubs, Group B, Mgrs 3 and 5	Pubs 50-59; Mgrs 3 and 5 (MSGF+ managers) (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2016-02-15 17:44:30	2023-07-31 14:41:18	PNL\\D3L243
154	R610 Pubs, Group C, Mgrs 3 and 5	Pubs 60-69; Mgrs 3 and 5 (MSGF+ managers) (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2016-02-15 17:44:45	2023-07-31 14:41:18	PNL\\D3L243
155	R610 Pubs, Group D, Mgrs 3 and 5	Pugs 70-79; Mgrs 3 and 5 (MSGF+ managers) (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2016-02-15 17:44:57	2023-07-31 14:41:18	PNL\\D3L243
156	R610 Pubs, Group E, Mgrs 3 and 5	Pubs 80-89; Mgrs 3 and 5 (MSGF+ managers) (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2016-02-15 17:45:06	2023-07-31 14:41:18	PNL\\D3L243
157	R610 Pubs, Group F, Mgrs 3 and 5	Pubs 94-97, mallard, diorite; Mgrs 3 and 5 (MSGF+ managers) (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2016-02-15 17:45:28	2023-07-31 14:41:18	PNL\\D3L243
158	300GB Pubs, Mgrs 3 and 5	Pubs 10-13, Pubs 90-93; Mgrs 3 and 5 (MSGF+ managers); have 300 GB (or larger) drives (disabled 2023-07-31 since processor groups were deprecated in May 2015)	N	2016-02-15 17:46:39	2023-07-31 14:41:18	PNL\\D3L243
\.


--
-- Name: t_analysis_job_processor_group_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_analysis_job_processor_group_group_id_seq', 158, true);


--
-- PostgreSQL database dump complete
--

