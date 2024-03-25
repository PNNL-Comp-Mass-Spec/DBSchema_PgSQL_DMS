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
-- Data for Name: t_eus_usage_type; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_eus_usage_type (eus_usage_type_id, eus_usage_type, description, enabled, enabled_campaign, enabled_prep_request) FROM stdin;
1	Undefined	Undefined type; not valid for requested runs	0	0	0
10	CAP_DEV	Capability Development	1	1	1
12	MAINTENANCE	Maintenance	1	0	0
13	BROKEN	Broken (out of service)	1	0	0
16	USER	On-Site usage (legacy name)	0	0	0
19	USER_UNKNOWN	EMSL Usage - To be specified later (should rarely be used)	0	0	0
20	USER_ONSITE	Samples analyzed onsite by originating user; prior to FY24, also used for samples associated with Resource Owner proposals	1	1	1
21	USER_REMOTE	Samples analyzed by instrumentation staff for an EMSL user	1	1	1
22	RESOURCE_OWNER	Samples analyzed on instrumentation owned by the project (non-EMSL); effective FY24, EUS project numbers are optional for Resource Owner samples	1	1	1
\.


--
-- Name: t_eus_usage_type_eus_usage_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_eus_usage_type_eus_usage_type_id_seq', 22, true);


--
-- PostgreSQL database dump complete
--

