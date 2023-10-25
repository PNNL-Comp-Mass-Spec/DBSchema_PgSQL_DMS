--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4
-- Dumped by pg_dump version 15.4

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
-- Data for Name: t_dataset_create_queue_state; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_create_queue_state (queue_state_id, queue_state_name) FROM stdin;
1	New
2	In Progress
3	Complete
4	Failed
5	Inactive
\.


--
-- PostgreSQL database dump complete
--

