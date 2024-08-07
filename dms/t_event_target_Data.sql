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
-- Data for Name: t_event_target; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_event_target (target_type_id, target_type, target_table, target_id_column, target_state_column) FROM stdin;
0	(none)	(none)	(none)	(none)
1	Campaign	t_campaign	campaign_id	(none)
2	Biomaterial	t_biomaterial	biomaterial_id	(none)
3	Experiment	t_experiments	exp_id	(none)
4	Dataset	t_dataset	dataset_id	dataset_state_id
5	Analysis Job	t_analysis_job	job	job_state_id
6	Archive	t_dataset_archive	dataset_id	archive_state_id
7	Archive Update	t_dataset_archive	dataset_id	archive_update_state_id
8	Dataset Rating	t_dataset	dataset_id	dataset_rating_id
9	Campaign Percent EMSL Funded	t_campaign	campaign_id	fraction_emsl_funded
11	Requested Run	t_requested_run	request_id	state_name
10	Campaign Data Release State	t_campaign	campaign_id	data_release_restrictions
12	Analysis Job Request	t_analysis_job_request	request_id	request_state_id
13	Reference Compound	t_reference_compound	compound_id	(none)
14	Requested Run Dataset ID	t_requested_run	dataset_id	(none)
15	Requested Run Experiment ID	t_requested_run	exp_id	(none)
\.


--
-- PostgreSQL database dump complete
--

