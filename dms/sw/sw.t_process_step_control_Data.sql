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
-- Data for Name: t_process_step_control; Type: TABLE DATA; Schema: sw; Owner: d3l243
--

COPY sw.t_process_step_control (processing_step_name, enabled, last_affected, entered_by) FROM stdin;
LogLevel	1	2015-05-04 10:42:35	PNL\\D3L243
UpdateDMS	1	2009-06-04 19:33:44	PNL\\D3L243
add_new_jobs	1	2010-02-03 14:19:33	pnl\\D3L243
add_update_jobs_in_development_database	0	2026-02-12 18:40:14.08113	d3l243
auto_fix_failed_jobs	1	2015-05-01 14:23:51	PNL\\D3L243
create_job_steps	1	2009-06-05 13:56:15	PNL\\D3L243
import_job_processors - Deprecated	0	2015-05-28 15:14:13	PNL\\D3L243
import_processors	1	2015-05-28 15:14:13	PNL\\D3L243
remove_dms_deleted_jobs	1	2025-01-09 19:28:16.817103	d3l243
sync_job_info	1	2009-06-05 13:50:15	PNL\\D3L243
update_cpu_loading	1	2009-06-05 13:50:15	PNL\\D3L243
update_job_state	1	2009-06-05 13:56:15	PNL\\D3L243
update_step_states	1	2014-09-17 16:18:17	PNL\\D3L243
\.


--
-- PostgreSQL database dump complete
--

