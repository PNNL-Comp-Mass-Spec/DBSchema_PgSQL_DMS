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
-- Data for Name: t_dataset_rating_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_rating_name (dataset_rating_id, dataset_rating) FROM stdin;
-10	Unreviewed
-7	Rerun (Superseded)
-6	Rerun (Good Data)
-5	Not Released
-4	Not released (allow analysis)
-2	Data Files Missing
-1	No Data (Blank/Bad)
1	No Interest
2	Unknown
3	Interest
5	Released
\.


--
-- PostgreSQL database dump complete
--

