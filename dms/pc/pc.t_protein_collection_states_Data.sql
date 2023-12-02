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
-- Data for Name: t_protein_collection_states; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_protein_collection_states (collection_state_id, state, description) FROM stdin;
0	Unknown	Protein collection does not exist
1	New	Newly entered, in development
2	Provisional	In Review before release to production
3	Production	Currently in use for analyses
4	Retired	No longer used for analyses, kept for legacy reasons
5	Proteins_Deleted	Protein names, descriptions, and sequences are no longer in the database
\.


--
-- PostgreSQL database dump complete
--

