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
-- Data for Name: t_cron_interval; Type: TABLE DATA; Schema: timetable; Owner: d3l243
--

COPY timetable.t_cron_interval (interval_id, cron_interval, interval_description) FROM stdin;
2	@reboot	When the PostgreSQL instance starts
3	0 2 * * *	Daily at 2:00 AM
4	45 23 15 * *	Monthly, on day 15 at 11:45 PM
5	0 22 1-5 * *	Monthly, on days 1-5 at 10:00 PM
6	30 22 * * *	Daily at 10:30:25 PM
7	20/30 * * * *	Every 30 minutes, starting at 12:20:40 AM
8	24 * * * *	Hourly, starting at 12:24:53 AM
9	23 8 3 * *	Monthly, on day 3 at 8:23:46 AM
10	53 * * * *	Hourly, starting at 12:53:39 AM
11	37 1/4 * * *	Every 4 hours, starting at 1:37 AM
13	19 17 * * *	Daily at 5:19:20 PM
14	27 0 * * *	Daily at 12:27:27 AM
15	0 0 * * *	Daily at 12:00:15 AM
16	9 4 * * 7	Weekly, on Sunday at 4:09 AM
17	15 5 * * 7	Weekly, on Sunday at 5:15:35 AM
18	48 6 * * *	Daily at 6:48 AM
12	7/15 3-23 * * *	Every 15 minutes, starting at 3:07:40 AM
1	23 */2 * * *	Every 2 hours, starting at 12:23 AM
\.


--
-- Name: t_cron_interval_interval_id_seq; Type: SEQUENCE SET; Schema: timetable; Owner: d3l243
--

SELECT pg_catalog.setval('timetable.t_cron_interval_interval_id_seq', 18, true);


--
-- PostgreSQL database dump complete
--

