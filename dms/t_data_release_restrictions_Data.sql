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
-- Data for Name: t_data_release_restrictions; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_data_release_restrictions (release_restriction_id, release_restriction) FROM stdin;
0	Not yet approved for release
1	Public data release allowed after time delay (contact PI)
2	Funding agency program officer permission required
3	Data cannot be publicly released
4	No restrictions (public release is allowed)
\.


--
-- PostgreSQL database dump complete
--

