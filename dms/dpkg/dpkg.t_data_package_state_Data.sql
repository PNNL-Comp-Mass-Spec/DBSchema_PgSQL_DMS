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
-- Data for Name: t_data_package_state; Type: TABLE DATA; Schema: dpkg; Owner: d3l243
--

COPY dpkg.t_data_package_state (state_name, description) FROM stdin;
Active	Package is currently being prepared
Complete	Package has been finalized; data has been sent to collaborator (if appropriate)
Future	Package has been created, but no data files have been added yet
Inactive	Package no longer contains useful data, or the data has been superseded
\.


--
-- PostgreSQL database dump complete
--

