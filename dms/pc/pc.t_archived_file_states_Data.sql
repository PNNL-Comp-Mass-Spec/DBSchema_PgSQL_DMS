--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
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
-- Data for Name: t_archived_file_states; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_archived_file_states (archived_file_state_id, archived_file_state, description) FROM stdin;
1	original	Collection archived as it existed when uploaded to the database
2	modified	Collection differs from originally loaded collection
3	Inactive	Collection is inactive; do not use
\.


--
-- Name: t_archived_file_states_archived_file_state_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_archived_file_states_archived_file_state_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

