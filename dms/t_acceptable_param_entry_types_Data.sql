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
-- Data for Name: t_acceptable_param_entry_types; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_acceptable_param_entry_types (param_entry_type_id, param_entry_type_name, description, formatting_string) FROM stdin;
1	Integer	\N	(?<value>\\d+)
2	MinMax	\N	(?<minimum>\\d+\\.\\d+)\\s+(?<maximum>\\d+\\.\\d+)
3	Text	\N	(?<value>\\S+)
4	NumericPicklist	\N	(?<value>\\d+)
5	IonSeries	\N	(?<use_a_ions>[0|1])\\s+(?<use_b_ions>[0|1])\\s+(?<use_y_ions>[0|1])\\s+(?<a_ion_weighting>\\d+\\.\\d+)\\s+(?<b_ion_weighting>\\d+\\.\\d+)\\s+(?<c_ion_weighting>\\d+\\.\\d+)\\s+(?<d_ion_weighting>\\d+\\.\\d+)\\s+(?<v_ion_weighting>\\d+\\.\\d+)\\s+(?<w_ion_weighting>\\d+\\.\\d+)\\s+(?<x_ion_weighting>\\d+\\.\\d+)\\s+(?<y_ion_weighting>\\d+\\.\\d+)\\s+(?<z_ion_weighting>\\d+\\.\\d+)
6	DiffMod	\N	(?<modMass>\\d+\\.\\d+)\\s+(?<affectedResidues>\\s+)
7	Float	\N	(?<value>\\d+\\.\\d+)
8	Boolean	\N	(?<value>[0|1])
9	TermDiffMod	\N	(?<nTermMass>\\d+\\.\\d+)\\s+(?<cTermMass>\\d+\\.\\d+)
\.


--
-- Name: t_acceptable_param_entry_types_param_entry_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_acceptable_param_entry_types_param_entry_type_id_seq', 9, true);


--
-- PostgreSQL database dump complete
--

