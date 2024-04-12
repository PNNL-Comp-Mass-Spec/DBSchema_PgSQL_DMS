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
-- Data for Name: t_dataset_archive_update_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_archive_update_state_name (archive_update_state_id, archive_update_state) FROM stdin;
0	(none)
1	New
2	Update Required
3	Update In Progress
4	Update Complete
5	Update Failed
6	Holding
\.


--
-- PostgreSQL database dump complete
--

