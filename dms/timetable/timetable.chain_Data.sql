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
-- Data for Name: chain; Type: TABLE DATA; Schema: timetable; Owner: d3l243
--

COPY timetable.chain (chain_id, chain_name, run_at, max_instances, timeout, live, self_destruct, exclusive_execution, client_name, on_error) FROM stdin;
3	run-vacuum	23 */2 * * *	\N	0	f	f	f	\N	\N
4	clear-log	@reboot	\N	0	t	f	f	\N	\N
6	Add missing predefined jobs	0 2 * * *	\N	0	t	f	f	\N	\N
8	Auto add BOM tracking datasets	45 23 15 * *	\N	0	t	f	f	\N	\N
10	Auto annotate broken instrument long intervals	0 22 1-5 * *	\N	0	t	f	f	\N	\N
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
\.


--
-- Name: chain_chain_id_seq; Type: SEQUENCE SET; Schema: timetable; Owner: d3l243
--

SELECT pg_catalog.setval('timetable.chain_chain_id_seq', 28, true);


--
-- PostgreSQL database dump complete
--

