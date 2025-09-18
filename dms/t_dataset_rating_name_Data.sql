--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
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
-- Data for Name: t_dataset_rating_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_rating_name (dataset_rating_id, dataset_rating, comment) FROM stdin;
-10	Unreviewed	
-7	Rerun (Superseded)	
-6	Rerun (Good Data)	
-5	Not Released	Not service center eligible
-4	Not Released (allow analysis)	Not service center eligible
-2	Data Files Missing	Not service center eligible
-1	No Data (Blank/Bad)	Not service center eligible
1	No Interest	
2	Unknown	
3	Interest	
5	Released	
6	Exclude From Service Center	Not service center eligible
7	Method Development	Not service center eligible
\.


--
-- PostgreSQL database dump complete
--

