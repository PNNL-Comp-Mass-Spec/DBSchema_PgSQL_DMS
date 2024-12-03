--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
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
-- Data for Name: t_dataset_archive_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_archive_state_name (archive_state_id, archive_state, comment) FROM stdin;
0	(na)	State is unknown
1	New	Dataset needs to be archived
2	Archive In Progress	Initial dataset archive is in progress
3	Complete	Dataset folder exists; may or may not contain the instrument data
4	Purged	Instrument data and all results are purged
5	Deleted	No longer used: Dataset has been deleted from the archive
6	Operation Failed	Operation failed
7	Purge In Progress	Dataset purge is in progress
8	Purge Failed	Dataset purge failed
9	Holding	Dataste archive / purge is on hold
10	NonPurgeable	Dataset is not purgeable
11	Verification Required	No longer used
12	Verification In Progress	No longer used
13	Verification Failed	No longer used
14	Purged Instrument Data (plus auto-purge)	Corresponds to Purge_Policy=0 (purge instrument data plus any auto-purge items)
15	Purged all data except QC folder	Corresponds to Purge_Policy=1 (purge all except QC folder)
\.


--
-- PostgreSQL database dump complete
--

