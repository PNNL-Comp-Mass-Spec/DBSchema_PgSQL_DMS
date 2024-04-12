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
-- Data for Name: t_aux_info_category; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_aux_info_category (aux_category_id, aux_category, target_type_id, sequence) FROM stdin;
1000	Lysis Method	500	2
1001	Denaturing Conditions	500	4
1002	Reducing Conditions	500	5
1003	Modification Parameters	500	6
1004	Fractionation before digestion	500	3
1005	Digestion Conditions	500	7
1006	Cleanup	500	9
1007	Other Post Digestion Procedures	500	8
1008	Final Conditions	500	10
1009	Storage	500	11
1011	Growth Conditions	501	0
1013	Cell Culture Mixing	500	1
1014	Separation Conditions	502	1
1016	Accounting	500	12
1017	Storage	501	4
1018	Storage	503	1
1019	Biohazard Precautions	503	2
1020	Experimental Design	501	5
\.


--
-- Name: t_aux_info_category_aux_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_aux_info_category_aux_category_id_seq', 1020, true);


--
-- PostgreSQL database dump complete
--

