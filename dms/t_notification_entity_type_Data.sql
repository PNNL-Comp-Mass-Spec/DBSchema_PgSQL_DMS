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
-- Data for Name: t_notification_entity_type; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_notification_entity_type (entity_type_id, entity_type) FROM stdin;
1	Requested Run Batch
2	Analysis_Job_Request
3	Sample Prep Request
4	Dataset Not Released
5	Dataset Released
\.


--
-- PostgreSQL database dump complete
--

