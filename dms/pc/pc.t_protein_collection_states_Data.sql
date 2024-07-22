--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
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
-- Data for Name: t_protein_collection_states; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_protein_collection_states (collection_state_id, state, description) FROM stdin;
0	Unknown	protein collection does not exist
1	New	newly entered, in development
2	Provisional	in review before release to production
3	Production	currently in use by analysis jobs
4	Retired	no longer used for analyses, kept for legacy reasons
6	Offline	protein names and sequences are no longer in the database; contact an admin to restore this protein collection using the FASTA file
5	Proteins_Deleted	protein names, descriptions, and sequences have been deleted from the database, and we do not have the corresponding FASTA file
\.


--
-- PostgreSQL database dump complete
--

