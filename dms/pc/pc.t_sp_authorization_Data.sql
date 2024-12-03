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
-- Data for Name: t_sp_authorization; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_sp_authorization (entry_id, procedure_name, login_name, host_name, host_ip) FROM stdin;
1	*	DMSWebUser	gigasax	130.20.225.2
2	*	DMSWebUser	prismweb2	130.20.224.55
9	*	DMSWebUser	prismweb2_IPv6	2620:0:50f1:118::5fd
12	*	DMSWebUser	prismweb2_IPv6_alt	2620:0:50f1:118::11fd
3	*	DMSWebUser	prismweb3	130.20.225.91
10	*	DMSWebUser	prismweb3_IPv6	2620:0:50f1:118::199
4	*	DMSWebUser	prismwebdev2	130.20.227.157
5	*	PNL\\D3L243	*	*
7	*	PNL\\gibb713	*	*
8	*	PNL\\memadmin	*	*
6	*	PNL\\svc-dms	*	*
11	*	pgdms	localhost	127.0.0.1
\.


--
-- Name: t_sp_authorization_entry_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_sp_authorization_entry_id_seq', 12, true);


--
-- PostgreSQL database dump complete
--

