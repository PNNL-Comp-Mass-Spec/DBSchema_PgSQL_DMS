--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.1

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
-- Data for Name: t_task_step_state_name; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_task_step_state_name (step_state_id, step_state, description) FROM stdin;
1	Waiting	Step has not been run yet, and it cannot be assigned yet.
2	Enabled	Step can be run because all its dependencies have been satisfied
3	Skipped	Step will not be run because a conditional dependency was triggered.
4	Running	Step has been assigned to a manager and is being processed
5	Completed	Manager has successfully completed step
6	Failed	Manager could not complete step successfully
7	Holding	Established and removed manually when deus ex machina is necessary
13	Inactive	Step aborted or failed, and we do not plan to re-run this step
\.


--
-- PostgreSQL database dump complete
--

