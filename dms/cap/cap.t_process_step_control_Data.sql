--
-- PostgreSQL database dump
--

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

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
-- Data for Name: t_process_step_control; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_process_step_control (processing_step_name, enabled, last_affected, entered_by) FROM stdin;
LogLevel	1	2023-06-19 20:34:43	PNL\\D3L243
UpdateDMS	1	2010-01-04 11:29:41	PNL\\D3J408
add_update_tasks_in_development_database	0	2026-02-12 18:37:53.548968	d3l243
create_task_steps	1	2009-09-05 08:58:09	PNL\\D3J410
make_new_archive_tasks_from_dms	1	2010-01-15 09:02:59	PNL\\D3J408
make_new_automatic_tasks	1	2009-09-11 15:53:40	PNL\\D3J410
make_new_tasks_from_analysis_broker	1	2010-01-14 13:20:50	PNL\\D3J408
make_new_tasks_from_dms	1	2010-01-20 13:49:08	PNL\\D3J408
update_task_state	1	2009-09-11 09:54:58	PNL\\D3J410
update_task_step_states	1	2009-09-05 12:29:30	PNL\\D3J410
\.


--
-- PostgreSQL database dump complete
--

