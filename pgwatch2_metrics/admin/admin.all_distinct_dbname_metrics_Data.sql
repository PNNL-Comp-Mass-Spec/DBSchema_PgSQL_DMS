--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
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
-- Data for Name: all_distinct_dbname_metrics; Type: TABLE DATA; Schema: admin; Owner: pgwatch2
--

COPY admin.all_distinct_dbname_metrics (dbname, metric, created_on) FROM stdin;
DMS	archiver	2024-04-17 15:08:40.763509-07
DMS	backends	2024-04-17 15:08:40.768362-07
DMS	backup_age_pgbackrest	2024-04-17 15:08:40.780148-07
DMS	bgwriter	2024-04-17 15:08:40.777678-07
DMS	configured_dbs	2024-04-18 16:21:42.034525-07
DMS	cpu_load	2024-04-17 15:08:40.774023-07
DMS	db_size	2024-04-17 15:08:40.781115-07
DMS	db_stats	2024-04-17 15:08:40.760511-07
DMS	index_stats	2024-04-17 15:08:40.765174-07
DMS	instance_up	2024-04-17 15:08:40.762727-07
DMS	kpi	2024-04-17 15:08:40.764507-07
DMS	locks	2024-04-17 15:08:40.761212-07
DMS	locks_mode	2024-04-17 15:08:40.766247-07
DMS	object_changes	2024-04-18 16:30:42.082101-07
DMS	psutil_cpu	2024-04-17 15:08:40.77959-07
DMS	psutil_disk	2024-04-17 15:08:40.774694-07
DMS	psutil_disk_io_total	2024-04-17 15:08:40.767207-07
DMS	psutil_mem	2024-04-17 15:08:40.763935-07
DMS	recommendations	2024-04-17 15:08:40.766707-07
DMS	sequence_health	2024-04-17 15:08:40.777887-07
DMS	server_log_event_counts	2024-04-17 15:08:40.772604-07
DMS	settings	2024-04-17 15:08:40.7739-07
DMS	sproc_changes	2024-04-25 21:32:57.876433-07
DMS	sproc_stats	2024-04-21 19:37:31.19979-07
DMS	stat_activity	2024-04-17 15:08:40.782831-07
DMS	stat_activity_realtime	2024-04-21 19:53:52.040306-07
DMS	stat_ssl	2024-04-17 15:08:40.77885-07
DMS	stat_statements	2024-04-17 15:08:40.769258-07
DMS	stat_statements_calls	2024-04-17 15:08:40.783376-07
DMS	table_bloat_approx_summary_sql	2024-04-17 15:08:40.778586-07
DMS	table_io_stats	2024-04-17 15:08:40.770959-07
DMS	table_stats	2024-04-17 15:08:40.773181-07
DMS	wal	2024-04-17 15:08:40.765536-07
DMS	wal_size	2024-04-17 15:08:40.77273-07
DMSDev	configured_dbs	2024-04-18 16:21:42.034525-07
DMSDev	cpu_load	2024-04-17 15:08:42.041528-07
DMSDev	db_size	2024-04-17 15:08:41.094857-07
DMSDev	db_stats	2024-04-17 15:08:41.631417-07
DMSDev	index_stats	2024-04-17 15:08:42.44968-07
DMSDev	sequence_health	2024-04-17 15:08:46.052792-07
DMSDev	sproc_stats	2024-08-06 22:31:24.397446-07
DMSDev	stat_statements	2024-04-17 15:08:48.520209-07
DMSDev	table_stats	2024-04-17 15:08:45.817186-07
DMSDev	wal	2024-04-17 15:08:47.818787-07
\.


--
-- PostgreSQL database dump complete
--

