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
-- Data for Name: t_sp_authorization; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_sp_authorization (entry_id, procedure_name, login_name, host_name, host_ip) FROM stdin;
1	*	DMSWebUser	gigasax	130.20.225.2
4	*	DMSWebUser	prismwebdev2	130.20.227.157
5	*	gigasax\\msdadmin	seqcluster5	0.0.0.0
6	*	PNL\\D3L243	*	*
16	*	PNL\\gibb713	*	*
17	*	PNL\\memadmin	*	*
18	*	PNL\\msdadmin	*	*
19	*	PNL\\svc-dms	*	*
20	*	DMSWebUser	WE43320	130.20.228.1
21	add_requested_run_batch_location_scan	LCMSNetUser	*	*
23	*	DMSWebUser	prismweb2_IPv6	2620:0:50f1:118::5fd
2	*	DMSWebUser	prismweb2	130.20.224.55
24	*	DMSWebUser	prismweb3_IPv6	2620:0:50f1:118::199
3	*	DMSWebUser	prismweb3	130.20.225.91
25	*	pgdms	localhost	127.0.0.1
\.


--
-- Name: t_sp_authorization_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_sp_authorization_entry_id_seq', 25, true);


--
-- PostgreSQL database dump complete
--

