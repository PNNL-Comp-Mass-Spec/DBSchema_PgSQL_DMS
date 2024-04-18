--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
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
DMS_PrismDB1	recommendations	2024-04-17 15:08:40.699458-07
DMS_PrismDB1	change_events	2024-04-17 15:08:40.702405-07
DMS_PrismDB1	server_log_event_counts	2024-04-17 15:08:40.714759-07
DMS_PrismDB2	sproc_stats	2024-04-17 15:08:40.757396-07
DMS_PrismDB2	db_stats	2024-04-17 15:08:40.760511-07
DMS_PrismDB2	locks	2024-04-17 15:08:40.761212-07
DMS_PrismDB2	instance_up	2024-04-17 15:08:40.762727-07
DMS_PrismDB2	archiver	2024-04-17 15:08:40.763509-07
DMS_PrismDB2	psutil_mem	2024-04-17 15:08:40.763935-07
DMS_PrismDB2	kpi	2024-04-17 15:08:40.764507-07
DMS_PrismDB2	index_stats	2024-04-17 15:08:40.765174-07
DMS_PrismDB2	wal	2024-04-17 15:08:40.765536-07
DMS_PrismDB2	locks_mode	2024-04-17 15:08:40.766247-07
DMS_PrismDB2	recommendations	2024-04-17 15:08:40.766707-07
DMS_PrismDB2	psutil_disk_io_total	2024-04-17 15:08:40.767207-07
DMS_PrismDB2	backends	2024-04-17 15:08:40.768362-07
DMS_PrismDB2	stat_statements	2024-04-17 15:08:40.769258-07
DMS_PrismDB2	replication_slots	2024-04-17 15:08:40.769785-07
DMS_PrismDB2	replication	2024-04-17 15:08:40.770553-07
DMS_PrismDB2	table_io_stats	2024-04-17 15:08:40.770959-07
DMS_PrismDB2	change_events	2024-04-17 15:08:40.771687-07
DMS_PrismDB2	wal_receiver	2024-04-17 15:08:40.771871-07
DMS_PrismDB2	server_log_event_counts	2024-04-17 15:08:40.772604-07
DMS_PrismDB2	wal_size	2024-04-17 15:08:40.77273-07
DMS_PrismDB2	table_stats	2024-04-17 15:08:40.773181-07
DMS_PrismDB2	settings	2024-04-17 15:08:40.7739-07
DMS_PrismDB2	cpu_load	2024-04-17 15:08:40.774023-07
DMS_PrismDB2	psutil_disk	2024-04-17 15:08:40.774694-07
DMS_PrismDB2	bgwriter	2024-04-17 15:08:40.777678-07
DMS_PrismDB2	sequence_health	2024-04-17 15:08:40.777887-07
DMS_PrismDB2	table_bloat_approx_summary_sql	2024-04-17 15:08:40.778586-07
DMS_PrismDB2	stat_ssl	2024-04-17 15:08:40.77885-07
DMS_PrismDB2	psutil_cpu	2024-04-17 15:08:40.77959-07
DMS_PrismDB2	backup_age_pgbackrest	2024-04-17 15:08:40.780148-07
DMS_PrismDB2	db_size	2024-04-17 15:08:40.781115-07
DMS_PrismDB2	logical_subscriptions	2024-04-17 15:08:40.782002-07
DMS_PrismDB2	stat_activity	2024-04-17 15:08:40.782831-07
DMS_PrismDB2	stat_statements_calls	2024-04-17 15:08:40.783376-07
DMS_PrismDB1	logical_subscriptions	2024-04-17 15:08:40.824306-07
DMS_PrismDB1	backends	2024-04-17 15:08:40.828173-07
DMS_PrismDB1	psutil_disk_io_total	2024-04-17 15:08:40.966262-07
DMS_PrismDB1	db_size	2024-04-17 15:08:41.094857-07
DMS_PrismDB1	sproc_stats	2024-04-17 15:08:41.221864-07
DMS_PrismDB1	wal_receiver	2024-04-17 15:08:41.491203-07
DMS_PrismDB1	db_stats	2024-04-17 15:08:41.631417-07
DMS_PrismDB1	wal_size	2024-04-17 15:08:41.900342-07
DMS_PrismDB1	cpu_load	2024-04-17 15:08:42.041528-07
DMS_PrismDB1	instance_up	2024-04-17 15:08:42.308158-07
DMS_PrismDB1	index_stats	2024-04-17 15:08:42.44968-07
DMS_PrismDB1	stat_ssl	2024-04-17 15:08:42.590711-07
DMS_PrismDB1	replication_slots	2024-04-17 15:08:42.730698-07
DMS_PrismDB1	psutil_cpu	2024-04-17 15:08:43.000447-07
DMS_PrismDB1	psutil_disk	2024-04-17 15:08:43.256485-07
DMS_PrismDB1	psutil_mem	2024-04-17 15:08:43.383123-07
DMS_PrismDB1	bgwriter	2024-04-17 15:08:43.523348-07
DMS_PrismDB1	backup_age_pgbackrest	2024-04-17 15:08:43.802272-07
DMS_PrismDB1	stat_statements_calls	2024-04-17 15:08:43.929128-07
DMS_PrismDB1	replication	2024-04-17 15:08:44.069873-07
DMS_PrismDB1	table_stats	2024-04-17 15:08:45.817186-07
DMS_PrismDB1	sequence_health	2024-04-17 15:08:46.052792-07
DMS_PrismDB1	locks_mode	2024-04-17 15:08:46.192994-07
DMS_PrismDB1	table_bloat_approx_summary_sql	2024-04-17 15:08:46.993507-07
DMS_PrismDB1	wal	2024-04-17 15:08:47.818787-07
DMS_PrismDB1	stat_statements	2024-04-17 15:08:48.520209-07
DMS_PrismDB1	stat_activity	2024-04-17 15:08:48.939049-07
DMS_PrismDB1	settings	2024-04-17 15:08:49.193667-07
DMS_PrismDB1	table_io_stats	2024-04-17 15:08:50.148488-07
DMS_PrismDB1	archiver	2024-04-17 15:08:51.112197-07
DMS_PrismDB1	kpi	2024-04-17 15:08:51.519757-07
DMS_PrismDB1	locks	2024-04-17 15:08:51.648414-07
\.


--
-- PostgreSQL database dump complete
--

