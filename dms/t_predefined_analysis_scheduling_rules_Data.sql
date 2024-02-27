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
-- Data for Name: t_predefined_analysis_scheduling_rules; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_predefined_analysis_scheduling_rules (rule_id, evaluation_order, instrument_class, instrument_name, dataset_name, analysis_tool_name, priority, processor_group_id, enabled, created) FROM stdin;
101	10		LTQ%	QC%	%Sequest%	1	100	1	2005-06-22 16:27:39
106	15	LTQ_FT			%MASIC%	1	115	0	2007-08-23 13:30:56
108	11		LTQ%	SE_QC%	%Sequest%	1	100	1	2008-04-11 15:44:44
110	14	LTQ_FT		mouseUSA%	%MASIC%	4	115	0	2008-10-06 14:55:03
112	10	Finnigan_Ion_Trap	LTQ%	GLBRC_Sc%	%Sequest%	2	135	1	2009-10-05 14:25:53
113	10	LTQ_FT	LTQ%	EIF_AIMS%	%Sequest%	2	109	1	2009-10-05 14:31:28
114	12	LTQ_FT		BATS%	%Sequest%	3	117	1	2010-11-08 10:19:23
118	13			QC%	%MSGFPlus%	1	100	1	2014-02-28 10:09:27
103	13			QC%	%XTandem%	1	100	1	2006-03-06 19:05:22
\.


--
-- Name: t_predefined_analysis_scheduling_rules_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_predefined_analysis_scheduling_rules_rule_id_seq', 120, true);


--
-- PostgreSQL database dump complete
--

