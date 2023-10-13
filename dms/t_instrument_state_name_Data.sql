--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4
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
-- Data for Name: t_instrument_state_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_state_name (state_name, description) FROM stdin;
Active	Instrument is online and available to use
Offline	Instrument is offline, but might be brought back online in the future
Inactive	Instrument has been retired and will not be brought back online
Broken	Instrument is broken, but might get repaired
PrepHPLC	Prep LC instrument that is in active use
\.


--
-- PostgreSQL database dump complete
--

