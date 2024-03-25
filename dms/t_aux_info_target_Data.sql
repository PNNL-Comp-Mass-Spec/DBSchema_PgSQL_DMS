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
-- Data for Name: t_aux_info_target; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_aux_info_target (target_type_id, target_type_name, target_table, target_id_col, target_name_col) FROM stdin;
500	Experiment	T_Experiments	Exp_ID	Experiment_Num
501	Biomaterial	T_Cell_Culture	CC_ID	CC_Name
502	Dataset	T_Dataset	Dataset_ID	Dataset_Num
503	SamplePrepRequest	T_Sample_Prep_Request	ID	ID
\.


--
-- Name: t_aux_info_target_target_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_aux_info_target_target_type_id_seq', 503, true);


--
-- PostgreSQL database dump complete
--

