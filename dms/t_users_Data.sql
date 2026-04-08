--
-- PostgreSQL database dump
--

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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
-- Data for Name: t_users; Type: TABLE DATA; Schema: public; Owner: d3l243
--
-- User list has been filtered to only include service accounts or placeholder users, as identified by this query
--   SELECT *
--   FROM t_users
--   WHERE Trim(Coalesce(email, '')) = '' AND NOT Status IN ('Inactive', 'Obsolete') OR hid LIKE 'H0909%'
--   ORDER BY user_id;
--

COPY public.t_users (user_id, username, name, hid, status, email, domain, payroll, active, update, created, comment, last_affected) FROM stdin;
2029	H0909090	Retrofit	H0909090	Active	\N	\N	\N	Y	N	2000-06-02 00:00:00.000		\N
2115	H09090911	AutoUser	H09090911	Inactive	\N	\N	\N	N	N	2004-06-18 00:00:00.000	\N	\N
2281	MSDADMIN	MSDADMIN	H0000000	Active	\N	\N	\N	Y	N	2009-01-01 00:00:00.000		\N
2321	MTSProc	MTSProcessor	MTSProc	Active	\N	PNL	\N	Y	N	2009-09-30 11:20:07.000		2009-09-30 11:20:07.000
2337	svc-dms	DMS service account	H0000000	Active	\N	\N	\N	Y	N	2010-02-05 12:26:03.000		2010-02-05 12:26:03.000
3628	pgdms	PostgresAutoUser	H09090912	Inactive		\N	\N	Y	N	2024-08-07 12:43:32.110438		2024-08-07 12:43:32.110438
3675	eustrim	EMSL EUS TRIM Connector	H0000000	Active		\N	\N	Y	N	2026-01-13 10:13:45.561288	Service account managed by Nathan Tenney and used by L7 to access DMS	2026-01-13 10:13:45.561288
\.


--
-- Name: t_users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_users_user_id_seq', 3679, true);


--
-- PostgreSQL database dump complete
--

