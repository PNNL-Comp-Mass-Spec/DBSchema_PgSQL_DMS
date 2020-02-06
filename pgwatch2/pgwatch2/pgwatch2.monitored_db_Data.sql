--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

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
-- Data for Name: monitored_db; Type: TABLE DATA; Schema: pgwatch2; Owner: pgwatch2
--

COPY pgwatch2.monitored_db (md_id, md_unique_name, md_hostname, md_port, md_dbname, md_user, md_password, md_is_superuser, md_sslmode, md_preset_config_name, md_config, md_is_enabled, md_last_modified_on, md_statement_timeout_seconds, md_dbtype, md_include_pattern, md_exclude_pattern, md_custom_tags, md_group, md_root_ca_path, md_client_cert_path, md_client_key_path, md_password_type, md_host_config, md_only_if_master) FROM stdin;
1	DMS_PrismWeb3	127.0.0.1	5432	dms	pgwatch2	DBMon...	t	disable	full	\N	t	2019-10-04 22:14:01.556742-07	5	postgres			\N	default				plain-text	\N	f
\.


--
-- Name: monitored_db_md_id_seq; Type: SEQUENCE SET; Schema: pgwatch2; Owner: pgwatch2
--

SELECT pg_catalog.setval('pgwatch2.monitored_db_md_id_seq', 1, true);


--
-- PostgreSQL database dump complete
--

