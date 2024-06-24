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
-- Data for Name: t_sp_authorization; Type: TABLE DATA; Schema: sw; Owner: d3l243
--

COPY sw.t_sp_authorization (entry_id, procedure_name, login_name, host_name, host_ip) FROM stdin;
1	*	DMSWebUser	gigasax	130.20.225.2
2	*	DMSWebUser	prismweb2	130.20.224.55
3	*	DMSWebUser	prismweb3	130.20.225.91
4	*	DMSWebUser	prismwebdev2	130.20.227.157
5	*	gigasax\\msdadmin	*	*
6	*	PNL\\D3L243	*	*
7	*	PNL\\gibb713	*	*
8	*	PNL\\memadmin	*	*
9	*	PNL\\msdadmin	gigasax	130.20.225.2
10	*	PNL\\msdadmin	seqcluster5	0.0.0.0
11	*	PNL\\svc-dms	*	*
12	*	DMSWebUser	prismweb2_IPv6	2620:0:50f1:118::5fd
13	*	DMSWebUser	prismweb3_IPv6	2620:0:50f1:118::199
14	*	pgdms	localhost	127.0.0.1
15	*	DMSWebUser	prismweb2_IPv6_alt	2620:0:50f1:118::11fd
\.


--
-- Name: t_sp_authorization_entry_id_seq; Type: SEQUENCE SET; Schema: sw; Owner: d3l243
--

SELECT pg_catalog.setval('sw.t_sp_authorization_entry_id_seq', 15, true);


--
-- PostgreSQL database dump complete
--

