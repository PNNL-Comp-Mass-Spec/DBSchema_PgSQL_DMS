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
-- Data for Name: t_research_team_roles; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_research_team_roles (role_id, role, description) FROM stdin;
1	Project Mgr	Project manager for project that owns the campaign
2	PI	Principle Investigator for the campaign
3	Technical Lead	Person to contact about details of work
4	Sample Preparation	Member of sample preparation team who is familiar with this campaign
5	Dataset Acquisition	
6	Informatics	
10	Observer	Person who wishes to receive notification of campaign-related events
\.


--
-- Name: t_research_team_roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_research_team_roles_role_id_seq', 10, true);


--
-- PostgreSQL database dump complete
--

