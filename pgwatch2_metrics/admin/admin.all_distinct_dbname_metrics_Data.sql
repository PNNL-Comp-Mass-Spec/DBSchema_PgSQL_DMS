--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3
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
-- Data for Name: all_distinct_dbname_metrics; Type: TABLE DATA; Schema: admin; Owner: pgwatch2
--

COPY admin.all_distinct_dbname_metrics (dbname, metric, created_on) FROM stdin;
DMS_PrismWeb3	server_log_event_counts	2020-05-12 11:43:35.545947-07
DMS_PrismWeb3	index_stats	2020-05-12 11:43:35.547106-07
DMS_PrismWeb3	cpu_load	2020-05-12 11:43:35.547835-07
DMS_PrismWeb3	psutil_disk	2020-05-12 11:43:35.548498-07
DMS_PrismWeb3	backends	2020-05-12 11:43:35.549109-07
DMS_PrismWeb3	table_stats	2020-05-12 11:43:35.54972-07
DMS_PrismWeb3	psutil_mem	2020-05-12 11:43:35.550358-07
DMS_PrismWeb3	stat_statements_calls	2020-05-12 11:43:35.550957-07
DMS_PrismWeb3	wal_size	2020-05-12 11:43:35.552083-07
DMS_PrismWeb3	settings	2020-05-12 11:43:35.552653-07
DMS_PrismWeb3	table_io_stats	2020-05-12 11:43:35.55321-07
DMS_PrismWeb3	stat_ssl	2020-05-12 11:43:35.554793-07
DMS_PrismWeb3	recommendations	2020-05-12 11:43:35.556687-07
DMS_PrismWeb3	wal	2020-05-12 11:43:35.557399-07
DMS_PrismWeb3	archiver	2020-05-12 11:43:35.558018-07
DMS_PrismWeb3	bgwriter	2020-05-12 11:43:35.558621-07
DMS_PrismWeb3	db_stats	2020-05-12 11:43:35.559877-07
DMS_PrismWeb3	table_bloat_approx_summary_sql	2020-05-12 11:43:35.560541-07
DMS_PrismWeb3	kpi	2020-05-12 11:43:35.561167-07
DMS_PrismWeb3	psutil_cpu	2020-05-12 11:43:35.561767-07
DMS_PrismWeb3	stat_statements	2020-05-12 11:43:35.561865-07
DMS_PrismWeb3	locks	2020-05-12 11:43:35.562454-07
DMS_PrismWeb3	db_size	2020-05-12 11:43:35.563627-07
DMS_PrismWeb3	locks_mode	2020-05-12 11:43:35.56476-07
DMS_PrismWeb3	psutil_disk_io_total	2020-05-12 11:43:35.566517-07
DMS_PrismWeb3	backup_age_pgbackrest	2020-05-12 12:43:15.068505-07
DMS_PrismWeb3	configuration_changes	2020-05-12 23:42:19.43765-07
DMS_PrismWeb3	configured_dbs	2020-05-12 23:42:19.439743-07
DMS_PrismWeb3	object_changes	2020-05-12 23:42:19.456712-07
DMS_PrismWeb3	sproc_changes	2020-05-12 23:42:19.473453-07
DMS_PrismWeb3	table_changes	2020-05-12 23:42:19.482651-07
DMS_PrismWeb3	psutil_disk_io_total_per_disk	2020-05-13 19:13:52.113185-07
DMS_PrismWeb3	index_changes	2020-05-14 10:07:53.944839-07
\.


--
-- PostgreSQL database dump complete
--

