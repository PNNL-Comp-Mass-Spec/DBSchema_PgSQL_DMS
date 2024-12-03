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
-- Data for Name: t_default_sp_params; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_default_sp_params (sp_name, param_name, param_value, description) FROM stdin;
make_new_tasks_from_analysis_broker	bypassDatasetArchive	1	waive the requirement that there be an existing complete dataset archive job in broker
make_new_tasks_from_analysis_broker	datasetIDFilterMax	0	If non-zero, then will be used to filter the candidate datasets
make_new_tasks_from_analysis_broker	datasetIDFilterMin	0	If non-zero, then will be used to filter the candidate datasets
make_new_tasks_from_analysis_broker	importWindowDays	10	Max days to go back in DMS archive table looking for results transfers
make_new_tasks_from_analysis_broker	loggingEnabled	0	Set to 1 to enable SP logging
make_new_tasks_from_analysis_broker	timeWindowToRequireExisingDatasetArchiveJob	30	Days
\.


--
-- PostgreSQL database dump complete
--

