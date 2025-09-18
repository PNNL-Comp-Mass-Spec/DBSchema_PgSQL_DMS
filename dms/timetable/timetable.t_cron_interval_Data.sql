--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
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
-- Data for Name: t_cron_interval; Type: TABLE DATA; Schema: timetable; Owner: d3l243
--

COPY timetable.t_cron_interval (interval_id, cron_interval, interval_description) FROM stdin;
88	00 10 * * *	At 10:00 AM
87	05 16 * * *	At 4:05 PM
86	22 16 * * *	At 4:22 PM
83	23 16 * * *	At 4:23 PM
85	25 16 * * *	At 4:25 PM
84	26 16 * * *	At 4:26 PM
79	0 18 10 5 *	At 6:00 PM on May 10th
78	0 9 10 5 *	At 9:00 AM on May 10th
59	14 22 * * *	Daily at 10:14 PM
39	27 22 * * *	Daily at 10:27 PM
6	30 22 * * *	Daily at 10:30 PM
54	59 23 * * *	Daily at 11:59 PM
15	0 0 * * *	Daily at 12:00 AM
23	0 12 * * *	Daily at 12:00 PM
56	11 0 * * *	Daily at 12:11 AM
40	13 0 * * *	Daily at 12:13 AM
14	27 0 * * *	Daily at 12:27 AM
3	0 2 * * *	Daily at 2:00 AM
48	37 2 * * *	Daily at 2:37 AM
58	53 2 * * *	Daily at 2:53 AM
13	19 17 * * *	Daily at 5:19 PM
52	42 5 * * *	Daily at 5:42 AM
22	0 6 * * *	Daily at 6:00 AM
24	0 18 * * *	Daily at 6:00 PM
94	12 6 * * *	Daily at 6:12 AM
32	12 18 * * *	Daily at 6:12 PM
57	15 6 * * *	Daily at 6:15 AM
18	48 6 * * *	Daily at 6:48 AM
62	25 19 * * *	Daily at 7:25 PM
21	38 7 * * *	Daily at 7:38 AM
80	10 20 * * *	Daily at 8:10pm
61	0 21 * * *	Daily at 9:00 PM
42	43 21 * * *	Daily at 9:43 PM
89	28 18 * * *	Daily, at 6:28 PM
35	* * * * *	Every 1 minute, starting at 12:00 AM
72	0/10 * * * *	Every 10 minutes, starting at 12:00 AM
12	7/15 3-23 * * *	Every 15 minutes, starting at 3:07 AM
1	23 */2 * * *	Every 2 hours, starting at 12:23 AM
36	0/20 * * * *	Every 20 minutes, starting at 12:00 AM
66	0 0/3 * * *	Every 3 hours, starting at 12:00 AM
64	1 0/3 * * *	Every 3 hours, starting at 12:01 AM
51	32 0/3 * * *	Every 3 hours, starting at 12:32 AM
55	15 3/3 * * *	Every 3 hours, starting at 3:15 AM
68	3 5/3 * * *	Every 3 hours, starting at 5:03 AM
25	7/30 * * * *	Every 30 minutes, starting at 12:07 AM
7	20/30 * * * *	Every 30 minutes, starting at 12:20 AM
82	21/30 * * * *	Every 30 minutes, starting at 12:21 AM
90	42/30 * * * *	Every 30 minutes, starting at 12:42 AM
11	37 1/4 * * *	Every 4 hours, starting at 1:37 AM
75	1/5 * * * *	Every 5 minutes, starting at 12:01 AM
69	2/5 * * * *	Every 5 minutes, starting at 12:02 AM
19	3/5 * * * *	Every 5 minutes, starting at 12:03 AM
65	0 0/6 * * *	Every 6 hours, starting at 12:00 AM
70	22 0/6 * * *	Every 6 hours, starting at 12:22 AM
49	24 0/6 * * *	Every 6 hours, starting at 12:24 AM
71	36 0/6 * * *	Every 6 hours, starting at 12:36 AM
33	42 0/6 * * *	Every 6 hours, starting at 12:42 AM
60	18 1/6 * * *	Every 6 hours, starting at 1:18 AM
73	37 1/6 * * *	Every 6 hours, starting at 1:37 AM
76	43 2/6 * * *	Every 6 hours, starting at 2:43 AM
67	43 6/6 * * *	Every 6 hours, starting at 6:43 AM
53	25 5/8 * * *	Every 8 hours, starting at 5:25 AM
37	17 * * * *	Hourly, starting at 12:17 AM
8	24 * * * *	Hourly, starting at 12:24 AM
45	36 * * * *	Hourly, starting at 12:36 AM
10	53 * * * *	Hourly, starting at 12:53 AM
27	17 1-23 * * *	Hourly, starting at 1:17 AM
26	23 3-23 * * *	Hourly, starting at 3:23 AM
34	3 22 * * 1,3,5	Monday, Wednesday, and Friday at 10:03 PM
4	45 23 15 * *	Monthly, on day 15 at 11:45 PM
9	23 8 3 * *	Monthly, on day 3 at 8:23 AM
20	19 19 6 * *	Monthly, on day 6 at 7:19 PM
5	0 22 1-5 * *	Monthly, on days 1-5 at 10:00 PM
81	10 21 * * 7	On Sunday, at 9:10pm
47	25 17 * * 2,5	Tuesday and Friday at 5:25 PM
46	14 23 * * 2,4,6	Tuesday, Thursday, Saturday at 11:14 PM
50	00 15 * * 3,7	Wednesday and Sunday at 3:00 PM
31	0 3 * * 5	Weekly, on Friday at 3:00 AM
30	15 18 * * 5	Weekly, on Friday at 6:15 PM
44	19 21 * * 5	Weekly, on Friday at 9:19 PM
41	12 10 * * 6	Weekly, on Saturday at 10:12 AM
43	15 16 * * 6	Weekly, on Saturday at 4:15 PM
38	38 16 * * 6	Weekly, on Saturday at 4:38 PM
74	17 17 * * 6	Weekly, on Saturday at 5:17 PM
77	28 18 * * 6	Weekly, on Saturday at 6:28 PM
63	38 15 * * 7	Weekly, on Sunday at 3:38 PM
16	9 4 * * 7	Weekly, on Sunday at 4:09 AM
17	15 5 * * 7	Weekly, on Sunday at 5:15 AM
93	05 00 * * 4	Weekly, on Thursday at 12:05 am
29	15 15 * * 4	Weekly, on Thursday at 3:15 PM
28	16 15 * * 4	Weekly, on Thursday at 3:16 PM
91	45 23 * * 3	Weekly, on Wednesday at 11:45 PM
2	@reboot	When the PostgreSQL instance starts
\.


--
-- Name: t_cron_interval_interval_id_seq; Type: SEQUENCE SET; Schema: timetable; Owner: d3l243
--

SELECT pg_catalog.setval('timetable.t_cron_interval_interval_id_seq', 94, true);


--
-- PostgreSQL database dump complete
--

