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
-- Data for Name: t_properties; Type: TABLE DATA; Schema: dpkg; Owner: d3l243
--

COPY dpkg.t_properties (property, value) FROM stdin;
MessageBroker1	prismdevii.pnl.gov
MessageBroker2	proto-10.pnl.gov
MessagePort	61613
MessageQueue	DMS.DataPackage.Command
\.


--
-- PostgreSQL database dump complete
--

