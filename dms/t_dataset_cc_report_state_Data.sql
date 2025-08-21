--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
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
-- Data for Name: t_dataset_cc_report_state; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_cc_report_state (cc_report_state_id, cc_report_state, description) FROM stdin;
0	Undefined	
1	Do not submit to service center	
2	Need to submit to service center	
3	Submitted to service center	
4	Need to refund to service center	
5	Refunded to service center	
\.


--
-- PostgreSQL database dump complete
--

