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
-- Data for Name: t_archive_space_usage; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_archive_space_usage (entry_id, sampling_date, data_mb, files, folders, comment, entered_by) FROM stdin;
21	2008-03-01 00:00:00	120314264	\N	\N		pnl\\D3L243
22	2008-04-01 00:00:00	123207680	\N	\N		pnl\\D3L243
23	2008-07-01 00:00:00	129236691	\N	\N		pnl\\D3L243
24	2009-01-16 00:00:00	145642400	\N	\N		pnl\\D3L243
25	2009-06-02 00:00:00	154777995	\N	\N		pnl\\D3L243
26	2009-08-21 00:00:00	163351537	\N	\N		pnl\\D3L243
27	2010-03-19 00:00:00	176327300	\N	\N		pnl\\D3L243
28	2010-05-18 00:00:00	179966344	\N	\N		pnl\\D3L243
29	2010-07-26 00:00:00	184455418	10002640	1828572		pnl\\D3L243
30	2011-05-09 00:00:00	223767707	11998363	2019692	Stats from http://msc/aurora.pl with user dmsarch	pnl\\D3L243
31	2011-07-15 00:00:00	231056170	12469605	2060867	Stats from http://msc/aurora.pl with user dmsarch	pnl\\D3L243
32	2011-07-28 00:00:00	232443709	12600260	2071391	Stats from http://msc/aurora.pl with user dmsarch	pnl\\D3L243
33	2012-06-27 00:00:00	274725077	17804864	2311477	Stats from http://msc/aurora.pl with user dmsarch	PNL\\D3L243
34	2013-03-27 00:00:00	308847575	22591351	1734971	Stats from http://msc.emsl.pnl.gov/robinhood/	PNL\\D3L243
35	2014-07-01 00:00:00	363490619	27782792	\N	Inferred using MyEMSL upload stats	PNL\\D3L243
37	2015-01-01 00:00:00	389567630	30396919	\N	Inferred using MyEMSL upload stats	PNL\\D3L243
38	2015-07-01 00:00:00	412562715	32157721	\N	Inferred using MyEMSL upload stats	PNL\\D3L243
1	2001-01-01 00:00:00	157286	\N	\N		pnl\\D3L243
2	2001-07-01 00:00:00	262144	\N	\N		pnl\\D3L243
3	2002-01-01 00:00:00	524288	\N	\N		pnl\\D3L243
4	2002-07-01 00:00:00	1048576	\N	\N		pnl\\D3L243
5	2003-01-01 00:00:00	2097152	\N	\N		pnl\\D3L243
6	2003-07-01 00:00:00	5242880	\N	\N		pnl\\D3L243
7	2004-01-01 00:00:00	10485760	\N	\N		pnl\\D3L243
8	2004-07-01 00:00:00	16777216	\N	\N		pnl\\D3L243
9	2005-01-01 00:00:00	26214400	\N	\N		pnl\\D3L243
10	2005-07-01 00:00:00	38797312	\N	\N		pnl\\D3L243
11	2006-01-01 00:00:00	52428800	\N	\N		pnl\\D3L243
12	2006-07-01 00:00:00	68157440	\N	\N		pnl\\D3L243
13	2006-12-21 00:00:00	84833280	\N	\N		pnl\\D3L243
14	2007-03-21 00:00:00	90960951	\N	\N		pnl\\D3L243
15	2007-07-23 00:00:00	100011336	\N	\N		pnl\\D3L243
16	2007-08-24 00:00:00	101880866	\N	\N		pnl\\D3L243
17	2007-10-12 00:00:00	105771780	\N	\N		pnl\\D3L243
18	2007-11-26 00:00:00	109073259	\N	\N		pnl\\D3L243
19	2008-01-01 00:00:00	113246208	\N	\N		pnl\\D3L243
20	2008-02-01 00:00:00	117958577	\N	\N		pnl\\D3L243
\.


--
-- Name: t_archive_space_usage_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_archive_space_usage_entry_id_seq', 38, true);


--
-- PostgreSQL database dump complete
--

