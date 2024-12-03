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
-- Data for Name: t_job_step_state_name; Type: TABLE DATA; Schema: sw; Owner: d3l243
--

COPY sw.t_job_step_state_name (step_state_id, step_state, description) FROM stdin;
1	Waiting	Step has not been run yet, and it cannot be assigned yet.
2	Enabled	Step can be run because all its dependencies have been satisfied
3	Skipped	Step will not be run because a conditional dependency was triggered.
4	Running	Step has been assigned to a manager and is being processed
5	Completed	Manager has successfully completed step
6	Failed	Manager could not complete step successfully
7	Holding	Established and removed manually when deus ex machina is necessary
9	Running_Remote	Job is running on a remote resource (Linux or Cloud)
10	Holding_Staging	Waiting for the Aurora data archive to stage the required files
11	Waiting_For_File	Waiting for another job to generate a required file
16	Failed_Remote	Job failed while running on a remote resource
\.


--
-- PostgreSQL database dump complete
--

