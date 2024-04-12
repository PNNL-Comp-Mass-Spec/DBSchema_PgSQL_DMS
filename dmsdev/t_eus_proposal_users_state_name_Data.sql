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
-- Data for Name: t_eus_proposal_users_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_eus_proposal_users_state_name (eus_user_state_id, eus_user_state) FROM stdin;
1	Associated with active proposal
2	Associated with inactive proposal
3	Unknown association; may need to delete
4	Permanently associated with proposal
5	No longer associated with proposal
\.


--
-- PostgreSQL database dump complete
--

