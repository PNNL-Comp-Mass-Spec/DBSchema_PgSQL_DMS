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
-- Data for Name: t_sp_authorization; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_sp_authorization (entry_id, procedure_name, login_name, host_name, host_ip, cascade_to_all_schema) FROM stdin;
20	*	DMSWebUser	WE43320	130.20.228.1	t
30	*	DMSWebUser	WE43320_IPv6	2620:0:50f1:118::3eb	t
1	*	DMSWebUser	gigasax	130.20.225.2	f
2	*	DMSWebUser	prismweb2	130.20.224.55	t
23	*	DMSWebUser	prismweb2_IPv6	2620:0:50f1:118::5fd	t
26	*	DMSWebUser	prismweb2_IPv6_alt	2620:0:50f1:118::11fd	t
3	*	DMSWebUser	prismweb3	130.20.225.91	t
24	*	DMSWebUser	prismweb3_IPv6	2620:0:50f1:118::1199	t
29	*	DMSWebUser	prismweb3_IPv6_alt	fe80::7c6:db6c:c606:c286	t
4	*	DMSWebUser	prismwebdev2	130.20.227.157	t
27	*	DMSWebUser	proto-2	130.20.230.113	f
28	*	DMSWebUser	proto-2_IPv6	2620:0:50f1:118::193b	f
21	add_requested_run_batch_location_scan	LCMSNetUser	*	*	f
6	*	PNL\\D3L243	*	*	f
31	*	PNL\\gibb166	*	*	f
16	*	PNL\\gibb713	*	*	f
17	*	PNL\\memadmin	*	*	f
18	*	PNL\\msdadmin	*	*	f
19	*	PNL\\svc-dms	*	*	f
25	*	pgdms	localhost	127.0.0.1	f
\.


--
-- Name: t_sp_authorization_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_sp_authorization_entry_id_seq', 31, true);


--
-- PostgreSQL database dump complete
--

