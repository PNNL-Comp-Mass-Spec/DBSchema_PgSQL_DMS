--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.2

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
DMSDev	object_changes	2024-04-22 20:10:57.351801-07
DMS	index_changes	2024-04-29 23:41:58.638075-07
DMS	db_stats	2024-04-17 15:08:40.760511-07
DMS	locks	2024-04-17 15:08:40.761212-07
DMS	instance_up	2024-04-17 15:08:40.762727-07
DMS	archiver	2024-04-17 15:08:40.763509-07
DMS	psutil_mem	2024-04-17 15:08:40.763935-07
DMS	kpi	2024-04-17 15:08:40.764507-07
DMS	index_stats	2024-04-17 15:08:40.765174-07
DMS	wal	2024-04-17 15:08:40.765536-07
DMS	locks_mode	2024-04-17 15:08:40.766247-07
DMS	recommendations	2024-04-17 15:08:40.766707-07
DMS	psutil_disk_io_total	2024-04-17 15:08:40.767207-07
DMS	backends	2024-04-17 15:08:40.768362-07
DMS	stat_statements	2024-04-17 15:08:40.769258-07
DMS	table_io_stats	2024-04-17 15:08:40.770959-07
DMS	server_log_event_counts	2024-04-17 15:08:40.772604-07
DMS	wal_size	2024-04-17 15:08:40.77273-07
DMS	table_stats	2024-04-17 15:08:40.773181-07
DMS	settings	2024-04-17 15:08:40.7739-07
DMS	cpu_load	2024-04-17 15:08:40.774023-07
DMS	psutil_disk	2024-04-17 15:08:40.774694-07
DMS	bgwriter	2024-04-17 15:08:40.777678-07
DMS	sequence_health	2024-04-17 15:08:40.777887-07
DMS	table_bloat_approx_summary_sql	2024-04-17 15:08:40.778586-07
DMS	stat_ssl	2024-04-17 15:08:40.77885-07
DMS	psutil_cpu	2024-04-17 15:08:40.77959-07
DMS	backup_age_pgbackrest	2024-04-17 15:08:40.780148-07
DMS	db_size	2024-04-17 15:08:40.781115-07
DMS	stat_activity	2024-04-17 15:08:40.782831-07
DMS	stat_statements_calls	2024-04-17 15:08:40.783376-07
DMS	configuration_changes	2024-04-18 16:20:42.02988-07
DMS	configured_dbs	2024-04-18 16:21:42.034525-07
DMS	object_changes	2024-04-18 16:30:42.082101-07
DMS	privilege_changes	2024-04-18 16:31:42.086365-07
DMSDev	recommendations	2024-04-17 15:08:40.699458-07
DMSDev	server_log_event_counts	2024-04-17 15:08:40.714759-07
DMSDev	backends	2024-04-17 15:08:40.828173-07
DMSDev	psutil_disk_io_total	2024-04-17 15:08:40.966262-07
DMSDev	db_size	2024-04-17 15:08:41.094857-07
DMSDev	db_stats	2024-04-17 15:08:41.631417-07
DMSDev	wal_size	2024-04-17 15:08:41.900342-07
DMSDev	cpu_load	2024-04-17 15:08:42.041528-07
DMSDev	instance_up	2024-04-17 15:08:42.308158-07
DMSDev	index_stats	2024-04-17 15:08:42.44968-07
DMSDev	stat_ssl	2024-04-17 15:08:42.590711-07
DMSDev	psutil_cpu	2024-04-17 15:08:43.000447-07
DMSDev	psutil_disk	2024-04-17 15:08:43.256485-07
DMSDev	psutil_mem	2024-04-17 15:08:43.383123-07
DMSDev	bgwriter	2024-04-17 15:08:43.523348-07
DMSDev	backup_age_pgbackrest	2024-04-17 15:08:43.802272-07
DMSDev	stat_statements_calls	2024-04-17 15:08:43.929128-07
DMSDev	table_stats	2024-04-17 15:08:45.817186-07
DMSDev	sequence_health	2024-04-17 15:08:46.052792-07
DMSDev	locks_mode	2024-04-17 15:08:46.192994-07
DMSDev	table_bloat_approx_summary_sql	2024-04-17 15:08:46.993507-07
DMSDev	wal	2024-04-17 15:08:47.818787-07
DMSDev	stat_statements	2024-04-17 15:08:48.520209-07
DMSDev	stat_activity	2024-04-17 15:08:48.939049-07
DMSDev	settings	2024-04-17 15:08:49.193667-07
DMSDev	table_io_stats	2024-04-17 15:08:50.148488-07
DMSDev	archiver	2024-04-17 15:08:51.112197-07
DMSDev	kpi	2024-04-17 15:08:51.519757-07
DMSDev	locks	2024-04-17 15:08:51.648414-07
DMSDev	configured_dbs	2024-04-18 16:21:42.034525-07
DMS	sproc_stats	2024-04-21 19:37:31.19979-07
DMSDev	stat_activity_realtime	2024-04-21 19:53:51.993124-07
DMS	stat_activity_realtime	2024-04-21 19:53:52.040306-07
DMS	sproc_changes	2024-04-25 21:32:57.876433-07
DMS	table_changes	2024-04-30 00:05:58.793318-07
DMSDev	configuration_changes	2024-05-15 14:02:56.232519-07
\.


--
-- PostgreSQL database dump complete
--

