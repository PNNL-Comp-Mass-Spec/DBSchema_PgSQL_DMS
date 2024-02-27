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
-- Data for Name: t_automatic_jobs; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_automatic_jobs (script_for_completed_job, script_for_new_job, enabled) FROM stdin;
DatasetArchive	SourceFileRename	1
DatasetArchive	MyEMSLVerify	1
LCDatasetCapture	ArchiveUpdate	1
DatasetCapture	LCDatasetCapture	1
\.


--
-- PostgreSQL database dump complete
--

