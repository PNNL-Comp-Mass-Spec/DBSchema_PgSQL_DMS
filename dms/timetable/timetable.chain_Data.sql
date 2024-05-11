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
-- Data for Name: chain; Type: TABLE DATA; Schema: timetable; Owner: d3l243
--

COPY timetable.chain (chain_id, chain_name, run_at, max_instances, timeout, live, self_destruct, exclusive_execution, client_name, on_error) FROM stdin;
3	run-vacuum	23 */2 * * *	\N	0	f	f	f	\N	\N
4	clear-log	@reboot	\N	0	t	f	f	\N	\N
59	Update cached NCBI taxonomy	19 21 * * 5	\N	0	t	f	f	\N	\N
60	Update cached requested run batch stats	36 * * * *	\N	0	t	f	f	\N	\N
61	Update cached requested run batch stats (full refresh)	14 23 * * 2,4,6	\N	0	t	f	f	\N	\N
62	Update cached requested run users (for active requests)	25 17 * * 2,5	\N	0	t	f	f	\N	\N
6	Add missing predefined jobs	0 2 * * *	\N	0	t	f	f	\N	\N
63	Update cached sample prep request items	37 2 * * *	\N	0	t	f	f	\N	\N
64	Update cached separation usage by dataset	24 0/6 * * *	\N	0	t	f	f	\N	\N
65	Update cached tissue names	00 15 * * 3,7	\N	0	t	f	f	\N	\N
8	Auto add BOM tracking datasets	45 23 15 * *	\N	0	t	f	f	\N	\N
10	Auto annotate broken instrument long intervals	0 22 1-5 * *	\N	0	t	f	f	\N	\N
66	Update capture task states	* * * * *	\N	0	t	f	f	\N	\N
11	Auto define WPS for EUS requested runs	30 22 * * *	\N	0	t	f	f	\N	\N
13	Auto reset failed jobs	20/30 * * * *	\N	0	t	f	f	\N	\N
14	Auto skip failed UIMF calibration	24 * * * *	\N	0	t	f	f	\N	\N
15	Auto supersede EUS proposals	23 8 3 * *	\N	0	t	f	f	\N	\N
16	Auto update job priorities	53 * * * *	\N	0	t	f	f	\N	\N
17	Auto update QC_Shew dataset rating	37 1/4 * * *	\N	0	t	f	f	\N	\N
22	Cache dataset QC instruments	37 1/4 * * *	\N	0	t	f	f	\N	\N
23	Check data integrity	19 17 * * *	\N	0	t	f	f	\N	\N
24	Check for MyEMSL upload errors	27 0 * * *	\N	0	t	f	f	\N	\N
25	Clean up operating logs	0 0 * * *	\N	0	t	f	f	\N	\N
26	Cleanup capture tasks	9 4 * * 7	\N	0	t	f	f	\N	\N
27	Cleanup pipeline jobs	15 5 * * 7	\N	0	t	f	f	\N	\N
28	Clear data package manager errors	48 6 * * *	\N	0	t	f	f	\N	\N
21	Backfill pipeline jobs	7/15 3-23 * * *	\N	0	t	f	f	\N	\N
29	Create pending predefined jobs	3/5 * * * *	\N	0	t	f	f	\N	\N
30	Delete old historic logs	19 19 6 * *	\N	0	t	f	f	\N	\N
31	Delete orphaned capture tasks	38 7 * * *	\N	0	t	f	f	\N	\N
34	DMS notification event update	0 12 * * *	\N	0	t	f	f	\N	\N
38	Find stale MyEMSL uploads	38 7 * * *	\N	0	t	f	f	\N	\N
42	Reset failed MyEMSL uploads	17 1-23 * * *	\N	0	t	f	f	\N	\N
39	Reset failed dataset capture tasks	7/30 * * * *	\N	0	t	f	f	\N	\N
43	Retire stale campaigns	16 15 * * 4	\N	0	t	f	f	\N	\N
44	Retire stale LC columns	15 15 * * 4	\N	0	t	f	f	\N	\N
45	Set external dataset purge priority	15 18 * * 5	\N	0	t	f	f	\N	\N
46	Store weekly project usage stats	0 3 * * 5	\N	0	t	f	f	\N	\N
47	Synchronize analysis job requests with jobs	12 18 * * *	\N	0	t	f	f	\N	\N
48	Update bionet host status	42 0/6 * * *	\N	0	t	f	f	\N	\N
49	Update cached analysis job state name and tool name	3 22 * * 1,3,5	\N	0	t	f	f	\N	\N
50	Update cached dataset folder paths, mode 0	* * * * *	\N	0	t	f	f	\N	\N
51	Update cached dataset folder paths, mode 1	0/20 * * * *	\N	0	t	f	f	\N	\N
52	Update cached dataset folder paths, mode 2	17 * * * *	\N	0	t	f	f	\N	\N
53	Update cached dataset folder paths, mode 3	38 16 * * 6	\N	0	t	f	f	\N	\N
54	Update cached dataset instruments	27 22 * * *	\N	0	t	f	f	\N	\N
55	Update cached dataset instruments (add new)	13 0 * * *	\N	0	t	f	f	\N	\N
56	Update cached experiment component names	12 10 * * 6	\N	0	t	f	f	\N	\N
57	Update cached instrument usage by proposal	43 21 * * *	\N	0	t	f	f	\N	\N
58	Update cached job request existing jobs	15 16 * * 6	\N	0	t	f	f	\N	\N
67	Update charge code usage	32 0/3 * * *	\N	0	t	f	f	\N	\N
68	Update charge codes from warehouse	42 5 * * *	\N	0	t	f	f	\N	\N
69	Update data package EUS info	25 5/8 * * *	\N	0	t	f	f	\N	\N
70	Update dataset intervals and emsl instrument usage	59 23 * * *	\N	0	t	f	f	\N	\N
71	Update dataset intervals every 3 hours	15 3/3 * * *	\N	0	t	f	f	\N	\N
72	Update DMS users from warehouse	11 0 * * *	\N	0	t	f	f	\N	\N
73	Update EUS proposals, users, and instruments	15 6 * * *	\N	0	t	f	f	\N	\N
74	Update EUS requested run WP	53 2 * * *	\N	0	t	f	f	\N	\N
75	Update experiment group member count	14 22 * * *	\N	0	t	f	f	\N	\N
76	Update experiment usage	18 1/6 * * *	\N	0	t	f	f	\N	\N
77	Update job step processing stats	0/20 * * * *	\N	0	t	f	f	\N	\N
78	Update missed DMS file info	0 21 * * *	\N	0	t	f	f	\N	\N
79	Update missed MyEMSL state info	25 19 * * *	\N	0	t	f	f	\N	\N
80	Update pipeline job states	* * * * *	\N	0	t	f	f	\N	\N
81	Update prep LC run work packages	38 15 * * 7	\N	0	t	f	f	\N	\N
82	Update status history, cap	1 0/3 * * *	\N	0	t	f	f	\N	\N
83	Update status history, public	0 0/6 * * *	\N	0	t	f	f	\N	\N
84	Update status history, sw	0 0/3 * * *	\N	0	t	f	f	\N	\N
85	Update tissue usage	43 6/6 * * *	\N	0	t	f	f	\N	\N
86	Update tracking tables	3 5/3 * * *	\N	0	t	f	f	\N	\N
87	Update waiting special processing jobs	2/5 * * * *	\N	0	t	f	f	\N	\N
88	Validate job and dataset states	22 0/6 * * *	\N	0	t	f	f	\N	\N
89	Delete timetable logs	36 0/6 * * *	\N	0	t	f	f	\N	\N
90	Update cached experiment stats, mode 0	0/10 * * * *	\N	0	t	f	f	\N	\N
91	Update cached experiment stats, mode 1	37 1/6 * * *	\N	0	t	f	f	\N	\N
37	Enable MS-GF+ once	33 20 * * *	\N	0	f	f	f	\N	\N
41	Reset failed analysis job managers	0 6 * * *	\N	0	f	f	f	\N	\N
33	Disable MSGFPlus once	31 20 * * *	\N	0	f	f	f	\N	\N
40	Reset failed dataset purge tasks	23 3-23 * * *	\N	0	f	f	f	\N	\N
92	Update cached experiment stats, mode 2	17 17 * * 6	\N	0	t	f	f	\N	\N
93	Update cached dataset stats, mode 0	1/5 * * * *	\N	0	t	f	f	\N	\N
95	Update cached dataset stats, mode 1	43 2/6 * * *	\N	0	t	f	f	\N	\N
96	Update cached dataset stats, mode 2	28 18 * * 6	\N	0	t	f	f	\N	\N
97	Promote protein collection states	10 20 * * *	\N	0	t	f	f	\N	\N
98	Promote protein collection states, 100 years	10 21 * * 7	\N	0	t	f	f	\N	\N
101	Disable Archive-Dependent Managers Once	22 16 * * *	\N	0	f	f	f	\N	\N
104	Enable Archive-Dependent Managers Once	23 16 * * *	\N	0	f	f	f	\N	\N
102	Disable Capture Task Managers Once	25 16 * * *	\N	0	f	f	f	\N	\N
103	Enable All Managers Once	26 16 * * *	\N	0	f	f	f	\N	\N
32	Disable archive-dependent step tools once	14 20 * * *	\N	0	f	f	f	\N	\N
36	Enable archive-dependent step tools once	27 20 * * *	\N	0	f	f	f	\N	\N
35	Enable archive update step tool once	49 20 * * *	\N	0	f	f	f	\N	\N
99	Disable All Managers Once	16 15 * * *	\N	0	f	f	f	\N	\N
100	Disable Analysis Managers Once	05 16 * * *	\N	0	f	f	f	\N	\N
\.


--
-- Name: chain_chain_id_seq; Type: SEQUENCE SET; Schema: timetable; Owner: d3l243
--

SELECT pg_catalog.setval('timetable.chain_chain_id_seq', 104, true);


--
-- PostgreSQL database dump complete
--

